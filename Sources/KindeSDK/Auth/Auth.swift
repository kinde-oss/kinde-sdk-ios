import AppAuth

/// The Kinde authentication service
public class Auth {
    @Atomic static var currentAuthorizationFlow: OIDExternalUserAgentSession?
    
    @Atomic private static var config: Config?
    @Atomic private static var authStateRepository: AuthStateRepository?
    @Atomic private static var logger: LoggerProtocol?
    /**
     `configure` must be called before `Auth` or any Kinde Management APIs are used.
     
     Set the host of the base URL of `OpenAPIClientAPI` to the business name extracted from the
     configured `issuer`. E.g., `https://example.kinde.com` -> `example`.
     */
    public static func configure(_ logger: LoggerProtocol? = nil) {
        self.config = Config.initialize()
        guard self.config != nil else {
            preconditionFailure("Failed to load configuration")
        }
        var loggerValue: LoggerProtocol?
        if logger == nil {
            loggerValue = DefaultLogger()
        }
        self.logger = loggerValue
        self.authStateRepository = AuthStateRepository(key: "\(Bundle.main.bundleIdentifier ?? "com.kinde.KindeAuth").authState", logger: logger)
        
        // Configure the Kinde Management API
        if let issuer = config?.issuer,
           let urlComponents = URLComponents(string: issuer),
           let host = urlComponents.host,
           let businessName = host.split(separator: ".").first {
            KindeSDKAPI.basePath = KindeSDKAPI.basePath.replacingOccurrences(of: "://app.", with: "://\(businessName).")
            
            // Use Bearer authentication subclass of RequestBuilderFactory
            KindeSDKAPI.requestBuilderFactory = BearerRequestBuilderFactory()
        } else {
            preconditionFailure("Failed to parse Business Name from configured issuer \(config?.issuer ?? "")")
        }
    }
    
    /// Is the user authenticated as of the last use of authentication state?
    public static func isAuthorized() -> Bool {
        return authStateRepository?.state?.isAuthorized ?? false
    }
    
    public static func isAuthenticated() -> Bool {
        let isAuthorized = authStateRepository?.state?.isAuthorized
        guard let lastTokenResponse = authStateRepository?.state?.lastTokenResponse else {
            return false
        }
        guard let accessTokenExpirationDate = lastTokenResponse.accessTokenExpirationDate else {
            return false
        }        
        return lastTokenResponse.accessToken != nil &&
               isAuthorized == true &&
               accessTokenExpirationDate > Date()
    }
    
    public static func getUserDetails() -> [String: Any?] {
        guard let params = authStateRepository?.state?.lastTokenResponse?.idToken?.parsedJWT else {
            return [:]
        }
        return ["id": params["sub"] as Any?,
                "given_name": params["given_name"] as Any?,
                "family_name": params["family_name"] as Any?,
                "email": params["email"] as Any?]
    }
    
    public static func getClaim(key: String, token: TokenType = .accessToken) -> Any? {
        let lastTokenResponse = authStateRepository?.state?.lastTokenResponse
        let tokenToParse = token == .accessToken ? lastTokenResponse?.accessToken: lastTokenResponse?.idToken
        guard let params = tokenToParse?.parsedJWT else {
            return nil
        }
        return params[key] ?? nil
    }
    
    public static func getPermissions() -> [String: Any?] {
        let permissions = getClaim(key: "permissions")
        let orgCode = getClaim(key: "org_code")
        return ["orgCode": orgCode,
                "permissions": permissions]
    }
    
    public static func getPermission(name: String) -> [String: Any?] {
        let permissions = getClaim(key: "permissions") as? [String] ?? []
        let orgCode = getClaim(key: "org_code")
        return ["orgCode": orgCode,
                "isGranted": permissions.contains(name)]
    }
    
    public static func getOrganization() -> [String: Any?] {
        let orgCode = getClaim(key: "org_code")
        return ["orgCode": orgCode]
    }
    
    public static func getUserOrganizations() -> [String: Any?] {
        let userOrgs = getClaim(key: "org_codes",
                                token: .idToken)
        return ["orgCodes": userOrgs]
    }
    
    private static func getViewController() async -> UIViewController? {
        await MainActor.run {
            let keyWindow = UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
                                                                .first { $0.isKeyWindow }
            var topController = keyWindow?.rootViewController
            while let presentedViewController = topController?.presentedViewController {
                topController = presentedViewController
            }
            return topController
        }
    }
    
    /// Register a new user
    ///
    @available(*, renamed: "register")
    public static func register(orgCode: String = "",
                         _ completion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            let result = await register(orgCode: orgCode)
            await MainActor.run {
                if let error = result {
                    completion(.failure(error))
                } else {
                    completion(.success(true))
                }
            }
        }
    }
    
    public static func register(orgCode: String = "") async -> (Error?) {
        guard let viewController = await getViewController() else {
            return AuthError.notAuthenticated
        }
        do {
            let (request, error) = try await asyncGetAuthorizationRequest(signUp: true, orgCode: orgCode)
            if let request = request {
                let (_, error) = try await runCurrentAuthorizationFlow(request: request, viewController: viewController)
                return error
            } else {
                return error
            }
        } catch {
            return error
        }
    }
    
    /// Login an existing user
    ///
    @available(*, renamed: "login")
    public static func login(orgCode: String = "",
                             _ completion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            let result = await login(orgCode: orgCode)
            await MainActor.run {
                if let error = result {
                    completion(.failure(error))
                } else {
                    completion(.success(true))
                }
            }
        }
    }

   public static func login(orgCode: String = "") async -> (Error?) {
        guard let viewController = await getViewController() else {
            return AuthError.notAuthenticated
        }
        do {
            let (request, error) = try await asyncGetAuthorizationRequest(signUp: false, orgCode: orgCode)
            if let request = request {
                let (_, error) = try await runCurrentAuthorizationFlow(request: request, viewController: viewController)
                return error
            } else {
                return error
            }
        } catch {
            return error
        }
    }
        
    /// Register a new organization
    ///
    @available(*, renamed: "createOrg")
    public static func createOrg( _ completion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            let result = await createOrg()
            await MainActor.run {
                if let error = result {
                    completion(.failure(error))
                } else {
                    completion(.success(true))
                }
            }
        }
    }

    public static func createOrg() async -> (Error?) {
        guard let viewController = await getViewController() else {
            return AuthError.notAuthenticated
        }
        do {
            let (request, error) = try await asyncGetAuthorizationRequest(signUp: true, createOrg: true)
            if let request = request {
                let (_, error) = try await runCurrentAuthorizationFlow(request: request, viewController: viewController)
                return error
            } else {
                return error
            }
        } catch {
            return error
        }
    }
    
    /// Logout the current user
    @available(*, renamed: "logout()")
    public static func logout(_ completion: @escaping (_ result: Bool) -> Void) {
        Task {
            let result = await logout()
            await MainActor.run {
                completion(result)
            }
        }
    }
    
    public static func logout() async -> Bool {
        // There is no logout endpoint configured; simply clear the local auth state
        let cleared = authStateRepository?.clear() ?? false
        return cleared
    }
    
    /// Create an Authorization Request using the configured Issuer and Redirect URLs,
    /// and OpenIDConnect configuration discovery
    @available(*, renamed: "getAuthorizationRequest(signUp:createOrg:orgCode:usePKCE:useNonce:)")
    private static func getAuthorizationRequest(signUp: Bool,
                                                createOrg: Bool = false,
                                                orgCode: String = "",
                                                usePKCE: Bool = true,
                                                useNonce: Bool = false,
                                                then completion: @escaping (Result<OIDAuthorizationRequest, Error>) -> Void) {
        Task {
            let (request, error) = await getAuthorizationRequest(signUp: signUp, createOrg: createOrg, orgCode: orgCode, usePKCE: usePKCE, useNonce: useNonce)
            await MainActor.run {
                if let request = request {
                    completion(.success(request))
                } else {
                    completion(.failure(error ?? AuthError.notAuthenticated))
                }
            }
        }
    }
    
    private static func getAuthorizationRequest(signUp: Bool,
                                                createOrg: Bool = false,
                                                orgCode: String = "",
                                                usePKCE: Bool = true,
                                                useNonce: Bool = false) async -> (OIDAuthorizationRequest?, Error?) {
        let issuerUrl = config?.getIssuerUrl()
        guard let issuerUrl = issuerUrl else {
            logger?.error(message: "Failed to get issuer URL")
            return (nil, AuthError.configuration)
        }
        do {
            let result = try await discoverConfiguration(issuerUrl: issuerUrl,
                                                         signUp: signUp,
                                                         createOrg: createOrg,
                                                         orgCode: orgCode,
                                                         usePKCE: usePKCE,
                                                         useNonce: useNonce)
            return (result, nil)
        } catch {
            return (nil, error)
        }
    }
    
    private static func runCurrentAuthorizationFlow(request: OIDAuthorizationRequest, viewController: UIViewController) async throws -> (Bool, Error?) {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                await MainActor.run {
                    currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request,
                                                                      presenting: viewController,
                                                                      callback: authorizationFlowCallback(then: { value in
                        switch value {
                        case .success:
                            continuation.resume(returning: (true, nil))
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }))
                }
            }
        }
    }
    
    private static func discoverConfiguration(issuerUrl: URL,
                                              signUp: Bool,
                                              createOrg: Bool = false,
                                              orgCode: String = "",
                                              usePKCE: Bool = true,
                                              useNonce: Bool = false) async throws -> (OIDAuthorizationRequest) {
        return try await withCheckedThrowingContinuation { continuation in
            OIDAuthorizationService.discoverConfiguration(forIssuer: issuerUrl) { configuration, error in
                if let error = error {
                    logger?.error(message: "Failed to discover OpenID configuration: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
                
                guard let configuration = configuration else {
                    logger?.error(message: "Failed to discover OpenID configuration")
                    continuation.resume(throwing: AuthError.configuration)
                    return
                }
                
                let redirectUrl = config?.getRedirectUrl()
                guard let redirectUrl = redirectUrl else {
                    logger?.error(message: "Failed to get redirect URL")
                    continuation.resume(throwing: AuthError.configuration)
                    return
                }
                
                var additionalParameters = [
                    "start_page": signUp ? "registration" : "login",
                    // Force fresh login
                    "prompt": "login"
                ]
                
                if createOrg {
                    additionalParameters["is_create_org"] = "true"
                }
                
                if let audience = config?.audience, !audience.isEmpty {
                   additionalParameters["audience"] = audience
                }
                
                if !orgCode.isEmpty {
                    additionalParameters["org_code"] = orgCode
                }
                
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
                
                continuation.resume(returning: request)
            }
        }
    }
    
    private static func asyncGetAuthorizationRequest(signUp: Bool,
                                                     createOrg: Bool = false,
                                                     orgCode: String = "",
                                                     usePKCE: Bool = true,
                                                     useNonce: Bool = false) async throws -> (OIDAuthorizationRequest?, Error?) {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                let result = await getAuthorizationRequest(signUp: signUp, orgCode: orgCode)
                continuation.resume(returning: result)
            }
        }
    }
    
    /// Callback to complete the current authorization flow
    private static func authorizationFlowCallback(then completion: @escaping (Result<Bool, Error>) -> Void) -> (OIDAuthState?, Error?) -> Void {
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
            completion(.success(true))
        }
    }
    
    /// Is the given error the result of user cancellation of an authorization flow
    public static func isUserCancellationErrorCode(_ error: Error) -> Bool {
        let error = error as NSError
        return error.domain == OIDGeneralErrorDomain && error.code == OIDErrorCode.userCanceledAuthorizationFlow.rawValue
    }
    
    /// Perform an action, such as an API call, with a valid access token and ID token
    /// Failure to get a valid access token may require reauthentication
    @available(*, renamed: "performWithFreshTokens()")
    static func performWithFreshTokens(_ action: @escaping (Result<Tokens, Error>) -> Void) {
        Task {
            do {
                if let result = try await performWithFreshTokens() {
                    action(.success(result))
                } else {
                    action(.failure(AuthError.notAuthenticated))
                }
            } catch {
                action(.failure(error))
            }
        }
    }

    static func performWithFreshTokens() async throws -> Tokens? {
        guard let authState = authStateRepository?.state else {
            logger?.error(message: "Failed to get authentication state")
            return nil
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            authState.performAction {(accessToken, idToken, error1) in
                if let error = error1 {
                    logger?.error(message: "Failed to get authentication tokens: \(error.localizedDescription)")
                    return continuation.resume(with: .failure(error))
                }
                
                guard let accessToken1 = accessToken else {
                    logger?.error(message: "Failed to get access token")
                    return continuation.resume(with: .failure(AuthError.notAuthenticated))
                }
                let tokens = Tokens(accessToken: accessToken1, idToken: idToken)
                continuation.resume(with: .success(tokens))
            }
        }
    }
}
