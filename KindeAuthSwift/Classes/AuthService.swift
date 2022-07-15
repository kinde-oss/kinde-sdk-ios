import AppAuth

/// The Kinde authentication service
public class AuthService: NSObject {
    var currentAuthorizationFlow: OIDExternalUserAgentSession?
    
    private let config: Config
    private let authStateRepository: AuthStateRepository
    private let logger: Logger?
    private var oidServiceConfiguration: OIDServiceConfiguration?

    public init(config: Config, logger: Logger?) {
        self.config = config
        self.logger = logger
        self.authStateRepository = AuthStateRepository(key: "\(Bundle.main.bundleIdentifier ?? "com.kinde.KindeAuth").authState", logger: logger)
    }
    
    /// Is the user authenticated as of the last use of authentication state
    public func isAuthorized() -> Bool {
        return self.authStateRepository.state?.isAuthorized ?? false
    }
    
    /// Register a new user
    public func register(viewController: UIViewController, _ completion: @escaping (Result<Void, Error>) -> Void) {
        getAuthorizationRequest(signUp: true, then: { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let request):
                self.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request,
                                                                       presenting: viewController,
                                                                       callback: self.authorizationFlowCallback(then: completion))
            }
        })
    }
    
    /// Login an existing user
    public func login(viewController: UIViewController, _ completion: @escaping (Result<Void, Error>) -> Void) {
        getAuthorizationRequest(signUp: false, then: { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let request):
                self.currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request,
                                                                       presenting: viewController,
                                                                       callback: self.authorizationFlowCallback(then: completion))
            }
        })
    }
    
    /// Logout the current user
    public func logout(viewController: UIViewController, _ completion: @escaping (_ result: Bool) -> Void) {
        // There is no logout endpoint configured; simply clear the local auth state
        let cleared = self.authStateRepository.clear()
        completion(cleared)
    }
    
    /// Create an Authorization Request using the configured Issuer and Redirect URLs,
    /// and OpenIDConnect configuration discovery
    private func getAuthorizationRequest(signUp: Bool, usePKCE: Bool = true, useNonce: Bool = false, then completion: @escaping (Result<OIDAuthorizationRequest, Error>) -> Void) {
        let issuerUrl = self.config.getIssuerUrl()
        guard let issuerUrl = issuerUrl else {
            self.logger?.error(message: "Failed to get issuer URL")
            return completion(.failure(AuthError.configuration))
        }
        
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuerUrl) { configuration, error in
            if let error = error {
                self.logger?.error(message: "Failed to discover OpenID configuration: \(error.localizedDescription)")
                return completion(.failure(error))
            }
            
            guard let configuration = configuration else {
                self.logger?.error(message: "Failed to discover OpenID configuration")
                return completion(.failure(AuthError.configuration))
            }
            
            let redirectUrl = self.config.getRedirectUrl()
            guard let redirectUrl = redirectUrl else {
                self.logger?.error(message: "Failed to get redirect URL")
                return completion(.failure(AuthError.configuration))
            }
            
            // TODO: force re-login; server doesn't yet support ["prompt" : "login"]
            let additionalParameters = ["start_page": signUp ? "registration" : "login", "is_skip_sso": "true"]
            
//            let scopes = self.config.scope.components(separatedBy: " ")
//            let request = OIDAuthorizationRequest(configuration: configuration,
//                                                  clientId: self.config.clientId,
//                                                  clientSecret: nil, // Only required for Client Credentials Flow
//                                                  scopes: scopes,
//                                                  redirectURL: redirectUrl,
//                                                  responseType: OIDResponseTypeCode,
//
            // TODO: prefer using the opinionated request builder above
            // if/when the API supports nonce validation
            let codeChallengeMethod = usePKCE ? OIDOAuthorizationRequestCodeChallengeMethodS256 : nil
            let codeVerifier = usePKCE ? OIDTokenUtilities.randomURLSafeString(withSize: 32) : nil
            let codeChallenge = usePKCE && codeVerifier != nil ? OIDTokenUtilities.encodeBase64urlNoPadding(OIDTokenUtilities.sha256(codeVerifier!)) : nil
            let state = OIDTokenUtilities.randomURLSafeString(withSize: 32)
            let nonce = useNonce ? OIDTokenUtilities.randomURLSafeString(withSize: 32) : nil

            let request = OIDAuthorizationRequest(configuration: configuration,
                                                  clientId: self.config.clientId,
                                                  clientSecret: nil, // Only required for Client Credentials Flow
                                                  scope: self.config.scope,
                                                  redirectURL: redirectUrl,
                                                  responseType: OIDResponseTypeCode,
                                                  state: state,
                                                  nonce: nonce,
                                                  codeVerifier: codeVerifier,
                                                  codeChallenge: codeChallenge,
                                                  codeChallengeMethod: codeChallengeMethod,
                                                  additionalParameters: additionalParameters)
            
            completion(.success(request))
        }
    }
    
    /// Callback to complete the current authorization flow
    private func authorizationFlowCallback(then completion: @escaping (Result<Void, Error>) -> Void) -> (OIDAuthState?, Error?) -> Void {
        return { authState, error in
            if let error = error {
                self.logger?.error(message: "Failed to finish authentication flow: \(error.localizedDescription)")
                _ = self.authStateRepository.clear()
                return completion(.failure(error))
            }
            
            guard let authState = authState else {
                self.logger?.error(message: "Failed to get authentication state")
                _ = self.authStateRepository.clear()
                return completion(.failure(AuthError.notAuthenticated))
            }
            
            self.logger?.debug(message: "Got authorization tokens. Access token: " +
                                      "\(authState.lastTokenResponse?.accessToken ?? "nil")")
            
            let saved = self.authStateRepository.setState(authState)
            if !saved {
                return completion(.failure(AuthError.failedToSaveState))
            }
            
            completion(.success(()))
        }
    }
    
    /// Perform an action, such as an API call, with a valid access token
    /// Failure to get a valid access token may require reauthentication
    public func performWithFreshTokens(_ action: @escaping (Result<String, Error>) -> Void) {
        guard let authState = self.authStateRepository.state else {
            self.logger?.error(message: "Failed to get authentication state")
            return action(.failure(AuthError.notAuthenticated))
        }
        
        authState.performAction {(accessToken, _, error) in
            if let error = error {
                self.logger?.error(message: "Failed to get authentication tokens: \(error.localizedDescription)")
                return action(.failure(error))
            }
            
            guard let accessToken = accessToken else {
                self.logger?.error(message: "Failed to get access token")
                return action(.failure(AuthError.notAuthenticated))
            }
                        
            action(.success(accessToken))
        }
    }
}

enum AuthError: Error {
    case configuration
    case notAuthenticated
    case failedToSaveState
}

/// A simple logging protocol with levels
public protocol Logger {
    func debug(message: String)
    func info(message: String)
    func error(message: String)
    func fault(message: String)
}
