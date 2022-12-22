import AppAuth

/// The Kinde authentication service
public class Auth: NSObject {
    static var currentAuthorizationFlow: OIDExternalUserAgentSession?
    
    private static var config: Config?
    private static var authStateRepository: AuthStateRepository?
    private static var logger: Logger?

    /**
     `configure` must be called before `Auth` or any Kinde Management APIs are used.
     
     Set the host of the base URL of `OpenAPIClientAPI` to the business name extracted from the
     configured `issuer`. E.g., `https://example.kinde.com` -> `example`.
     */
    public static func configure(from source: Config.Source = .plist, logger: Logger?) {
        self.config = Config.from(source)
        guard self.config != nil else {
            preconditionFailure("Failed to load configuration")
        }
        self.logger = logger
        self.authStateRepository = AuthStateRepository(key: "\(Bundle.main.bundleIdentifier ?? "com.kinde.KindeAuth").authState", logger: logger)
        
        // Configure the Kinde Management API
        if let issuer = config?.issuer,
           let urlComponents = URLComponents(string: issuer),
           let host = urlComponents.host,
           let businessName = host.split(separator: ".").first {
            OpenAPIClientAPI.basePath = OpenAPIClientAPI.basePath.replacingOccurrences(of: "://app.", with: "://\(businessName).")
            
            // Use Bearer authentication subclass of RequestBuilderFactory
            OpenAPIClientAPI.requestBuilderFactory = BearerRequestBuilderFactory()
        } else {
            preconditionFailure("Failed to parse Business Name from configured issuer \(config?.issuer ?? "")")
        }
        
    }
    
    /// Is the user authenticated as of the last use of authentication state?
    public static func isAuthorized() -> Bool {
        return authStateRepository?.state?.isAuthorized ?? false
    }
    
    /// Register a new user
    public static func register(viewController: UIViewController, _ completion: @escaping (Result<Void, Error>) -> Void) {
        getAuthorizationRequest(signUp: true, then: { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let request):
                currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request,
                                                                  presenting: viewController,
                                                                  callback: authorizationFlowCallback(then: completion))
            }
        })
    }
    
    /// Login an existing user
    public static func login(viewController: UIViewController, _ completion: @escaping (Result<Void, Error>) -> Void) {
        getAuthorizationRequest(signUp: false, then: { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let request):
                currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request,
                                                                  presenting: viewController,
                                                                  callback: authorizationFlowCallback(then: completion))
            }
        })
    }
    
    /// Logout the current user
    public static func logout(viewController: UIViewController, _ completion: @escaping (_ result: Bool) -> Void) {
        // There is no logout endpoint configured; simply clear the local auth state
        let cleared = authStateRepository?.clear() ?? false
        completion(cleared)
    }
    
    /// Create an Authorization Request using the configured Issuer and Redirect URLs,
    /// and OpenIDConnect configuration discovery
    private static func getAuthorizationRequest(signUp: Bool, usePKCE: Bool = true, useNonce: Bool = false, then completion: @escaping (Result<OIDAuthorizationRequest, Error>) -> Void) {
        let issuerUrl = config?.getIssuerUrl()
        guard let issuerUrl = issuerUrl else {
            logger?.error(message: "Failed to get issuer URL")
            return completion(.failure(AuthError.configuration))
        }
        
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuerUrl) { configuration, error in
            if let error = error {
                logger?.error(message: "Failed to discover OpenID configuration: \(error.localizedDescription)")
                return completion(.failure(error))
            }
            
            guard let configuration = configuration else {
                logger?.error(message: "Failed to discover OpenID configuration")
                return completion(.failure(AuthError.configuration))
            }
            
            let redirectUrl = config?.getRedirectUrl()
            guard let redirectUrl = redirectUrl else {
                logger?.error(message: "Failed to get redirect URL")
                return completion(.failure(AuthError.configuration))
            }
            
            let additionalParameters = [
                "start_page": signUp ? "registration" : "login",
                // Force fresh login
                "prompt": "login"
            ]
            
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
                                                  clientId: config?.clientId ?? "",
                                                  clientSecret: nil, // Only required for Client Credentials Flow
                                                  scope: config?.scope ?? "",
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
    private static func authorizationFlowCallback(then completion: @escaping (Result<Void, Error>) -> Void) -> (OIDAuthState?, Error?) -> Void {
        return { authState, error in
            if let error = error {
                logger?.error(message: "Failed to finish authentication flow: \(error.localizedDescription)")
                _ = authStateRepository?.clear()
                return completion(.failure(error))
            }
            
            guard let authState = authState else {
                logger?.error(message: "Failed to get authentication state")
                _ = authStateRepository?.clear()
                return completion(.failure(AuthError.notAuthenticated))
            }
            
            logger?.debug(message: "Got authorization tokens. Access token: " +
                                      "\(authState.lastTokenResponse?.accessToken ?? "nil")")
            
            let saved = authStateRepository?.setState(authState) ?? false
            if !saved {
                return completion(.failure(AuthError.failedToSaveState))
            }
            
            currentAuthorizationFlow = nil
            completion(.success(()))
        }
    }
    
    /// Is the given error the result of user cancellation of an authorization flow
    public static func isUserCancellationErrorCode(_ error: Error) -> Bool {
        let error = error as NSError
        return error.domain == OIDGeneralErrorDomain && error.code == OIDErrorCode.userCanceledAuthorizationFlow.rawValue
    }
    
    /// Perform an action, such as an API call, with a valid access token and ID token
    /// Failure to get a valid access token may require reauthentication
    public static func performWithFreshTokens(_ action: @escaping (Result<Tokens, Error>) -> Void) {
        guard let authState = authStateRepository?.state else {
            logger?.error(message: "Failed to get authentication state")
            return action(.failure(AuthError.notAuthenticated))
        }

        authState.performAction {(accessToken, idToken, error) in
            if let error = error {
                logger?.error(message: "Failed to get authentication tokens: \(error.localizedDescription)")
                return action(.failure(error))
            }

            guard let accessToken = accessToken else {
                logger?.error(message: "Failed to get access token")
                return action(.failure(AuthError.notAuthenticated))
            }

            action(.success(Tokens(accessToken: accessToken, idToken: idToken)))
        }
    }
}

/// Authentication and identity tokens from the Kinde service
public struct Tokens {
    /// A bearer token for making authenticated calls to Kinde endpoints
    public var accessToken: String
    /// An ID token for the subject of the `accessToken`
    public var idToken: String?
}

public enum AuthError: Error {
    /// Failed to retrieve local or remote configuration
    case configuration
    /// Failed to obtain valid authentication state
    case notAuthenticated
    /// Failed to save authentication state on device
    case failedToSaveState
}

extension AuthError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .configuration:
            return NSLocalizedString(
                "Failed to retrieve local or remote configuration.",
                comment: "Invalid Configuration"
            )
        case .notAuthenticated:
            return NSLocalizedString(
                "Failed to obtain valid authentication state.",
                comment: "Not Authenticated"
            )
        case .failedToSaveState:
            return NSLocalizedString(
                "Failed to save authentication state on device.",
                comment: "Failed State Persistence"
            )
        }
    }
}

/// A simple logging protocol with levels
public protocol Logger {
    func debug(message: String)
    func info(message: String)
    func error(message: String)
    func fault(message: String)
}
