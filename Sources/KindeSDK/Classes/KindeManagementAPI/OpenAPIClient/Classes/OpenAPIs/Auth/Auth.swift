import AppAuth

/// The Kinde authentication service
public class Auth {
    @Atomic static var currentAuthorizationFlow: OIDExternalUserAgentSession?
    
    @Atomic private static var config: Config?
    @Atomic private static var authStateRepository: AuthStateRepository?
    @Atomic private static var logger: Logger?

    /**
     `configure` must be called before `Auth` or any Kinde Management APIs are used.
     
     Set the host of the base URL of `OpenAPIClientAPI` to the business name extracted from the
     configured `issuer`. E.g., `https://example.kinde.com` -> `example`.
     */
    public static func configure(_ logger: Logger? = nil) {
        self.config = Config.initialize()
        guard self.config != nil else {
            preconditionFailure("Failed to load configuration")
        }
        var loggerValue: Logger?
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
        return [idDetailsKey: params[subDetailsKey] as Any?,
                givenNameDetailsKey: params[givenNameDetailsKey] as Any?,
                familyNameDetailsKey: params[familyNameDetailsKey] as Any?,
                emailDetailsKey: params[emailDetailsKey] as Any?]
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
        let permissions = getClaim(key: permissionsClaimKey)
        let orgCode = getClaim(key: orgCodeClaimKey)
        return ["orgCode": orgCode,
                "permissions": permissions]
    }
    
    public static func getPermission(name: String) -> [String: Any?] {
        let permissions = getClaim(key: permissionsClaimKey) as? [String] ?? []
        let orgCode = getClaim(key: orgCodeClaimKey)
        return ["orgCode": orgCode,
                "isGranted": permissions.contains(name)]
    }
    
    public static func getOrganization() -> [String: Any?] {
        let orgCode = getClaim(key: orgCodeClaimKey)
        return ["orgCode": orgCode]
    }
    
    public static func getUserOrganizations() -> [String: Any?] {
        let userOrgs = getClaim(key: orgCodesClaimKey,
                                token: .idToken)
        return ["orgCodes": userOrgs]
    }
    
    private static func getViewController() async -> UIViewController? {
        await MainActor.run {
            let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
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
                completion(result)
            }
        }
    }
    
    public static func register(orgCode: String = "") async -> (Result<Bool, Error>) {
        guard let viewController = await getViewController() else {
            return .failure(AuthError.notAuthenticated)
        }
        do {
            let result = try await asyncGetAuthorizationRequest(signUp: true, orgCode: orgCode)
            switch result {
            case .success(let request):
                do {
                    _ = try await runCurrentAuthorizationFlow(request: request, viewController: viewController)
                    return .success(true)
                } catch {
                    return .failure(error)
                }
            case .failure(let error):
                return .failure(error)
            }
        } catch {
            return .failure(error)
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
                completion(result)
            }
        }
    }

    public static func login(orgCode: String = "") async -> (Result<Bool, Error>) {
        guard let viewController = await getViewController() else {
            return .failure(AuthError.notAuthenticated)
        }
        
        do {
            let result = try await asyncGetAuthorizationRequest(signUp: false, orgCode: orgCode)
            switch result {
            case .success(let request):
                do {
                    _ = try await runCurrentAuthorizationFlow(request: request, viewController: viewController)
                    return .success(true)
                } catch {
                    return .failure(error)
                }
            case .failure(let error):
                return .failure(error)
            }
        } catch {
            return .failure(error)
        }
    }
        
    /// Register a new organization
    ///
    @available(*, renamed: "createOrg")
    public static func createOrg( _ completion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            let result = await createOrg()
            await MainActor.run {
                completion(result)
            }
        }
    }

    public static func createOrg() async -> (Result<Bool, Error>) {
        guard let viewController = await getViewController() else {
            return .failure(AuthError.notAuthenticated)
        }
        
        do {
            let result = try await asyncGetAuthorizationRequest(signUp: true, createOrg: true)
            switch result {
            case .success(let request):
                do {
                    _ = try await runCurrentAuthorizationFlow(request: request, viewController: viewController)
                    return .success(true)
                } catch {
                    return .failure(error)
                }
            case .failure(let error):
                return .failure(error)
            }
        } catch {
            return .failure(error)
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
            let result = await getAuthorizationRequest(signUp: signUp, createOrg: createOrg, orgCode: orgCode, usePKCE: usePKCE, useNonce: useNonce)
            await MainActor.run {
                completion(result)
            }
            
        }
    }
    
    private static func getAuthorizationRequest(signUp: Bool,
                                                createOrg: Bool = false,
                                                orgCode: String = "",
                                                usePKCE: Bool = true,
                                                useNonce: Bool = false) async -> (Result<OIDAuthorizationRequest, Error>) {
        let issuerUrl = config?.getIssuerUrl()
        guard let issuerUrl = issuerUrl else {
            logger?.error(message: "Failed to get issuer URL")
            return .failure(AuthError.configuration)
        }
        do {
            let result = try await discoverConfiguration(issuerUrl: issuerUrl,
                                                         signUp: signUp,
                                                         createOrg: createOrg,
                                                         orgCode: orgCode,
                                                         usePKCE: usePKCE,
                                                         useNonce: useNonce)
            return .success(result)
        } catch {
            return .failure(error)
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
                    startPageParamName: signUp ? "registration" : "login",
                    // Force fresh login
                    promptParamName: "login"
                ]
                
                if createOrg {
                    additionalParameters[isCreateOrgParamName] = "true"
                }
                
                if let audience = config?.audience, !audience.isEmpty {
                   additionalParameters[audienceParamName] = audience
                }
                
                if !orgCode.isEmpty {
                    additionalParameters[orgCodeParamName] = orgCode
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
                                                     useNonce: Bool = false) async throws -> (Result<OIDAuthorizationRequest, Error>) {
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

/// Authentication and identity tokens from the Kinde service
public struct Tokens {
    /// A bearer token for making authenticated calls to Kinde endpoints
    var accessToken: String
    /// An ID token for the subject of the `accessToken`
    var idToken: String?
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

public enum TokenType: String {
    case idToken
    case accessToken
}

private let idDetailsKey = "id"
private let subDetailsKey = "sub"
private let givenNameDetailsKey = "given_name"
private let familyNameDetailsKey = "family_name"
private let emailDetailsKey = "email"

private let permissionsClaimKey = "permissions"
private let orgCodeClaimKey = "org_code"
private let orgCodesClaimKey = "org_codes"

private let audienceParamName = "audience"
private let isCreateOrgParamName = "is_create_org"
private let orgCodeParamName = "org_code"
private let startPageParamName = "start_page"
private let promptParamName = "prompt"

/// A simple logging protocol with levels
public protocol Logger {
    func debug(message: String)
    func info(message: String)
    func error(message: String)
    func fault(message: String)
}

extension String {
    var parsedJWT: [String: Any?] {
        let tokenString = self
        var params: [String: Any?] = [:]
        do {
            let data = try decode(jwtToken: tokenString)
            params = data
        } catch {
            preconditionFailure("\(error.localizedDescription)")
        }
        return params
    }
    
    func decode(jwtToken jwt: String) throws -> [String: Any] {
        enum DecodeErrors: Error {
            case badToken
            case other
        }

        func base64Decode(_ base64: String) throws -> Data {
            let base64 = base64
                .replacingOccurrences(of: "-", with: "+")
                .replacingOccurrences(of: "_", with: "/")
            let padded = base64.padding(toLength: ((base64.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
            guard let decoded = Data(base64Encoded: padded) else {
                throw DecodeErrors.badToken
            }
            return decoded
        }

        func decodeJWTPart(_ value: String) throws -> [String: Any] {
            let bodyData = try base64Decode(value)
            let json = try JSONSerialization.jsonObject(with: bodyData, options: [])
            guard let payload = json as? [String: Any] else {
                throw DecodeErrors.other
            }
            return payload
        }

        let segments = jwt.components(separatedBy: ".")
        return try decodeJWTPart(segments[1])
    }
}

@propertyWrapper struct Atomic<Value> {
    private var value: Value
    private let lock = NSLock()

    init(wrappedValue value: Value) {
        self.value = value
    }

    var wrappedValue: Value {
      get { return load() }
      set { store(newValue: newValue) }
    }

    func load() -> Value {
        lock.lock()
        defer { lock.unlock() }
        return value
    }

    mutating func store(newValue: Value) {
        lock.lock()
        defer { lock.unlock() }
        value = newValue
    }
}
