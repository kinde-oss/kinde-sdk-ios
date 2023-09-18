import AppAuth

/// The Kinde authentication service
public final class Auth {
    @Atomic private var currentAuthorizationFlow: OIDExternalUserAgentSession?
    
    private let config: Config
    private let authStateRepository: AuthStateRepository
    private let logger: LoggerProtocol
    private var privateAuthSession: Bool = false
    
    init(config: Config, authStateRepository: AuthStateRepository, logger: LoggerProtocol) {
        self.config = config
        self.authStateRepository = authStateRepository
        self.logger = logger
    }
    
    /// Is the user authenticated as of the last use of authentication state?
    public func isAuthorized() -> Bool {
        return authStateRepository.state?.isAuthorized ?? false
    }
    
    public func isAuthenticated() -> Bool {
        let isAuthorized = authStateRepository.state?.isAuthorized
        guard let lastTokenResponse = authStateRepository.state?.lastTokenResponse else {
            return false
        }
        guard let accessTokenExpirationDate = lastTokenResponse.accessTokenExpirationDate else {
            return false
        }
        return lastTokenResponse.accessToken != nil &&
               isAuthorized == true &&
               accessTokenExpirationDate > Date()
    }
    
    public func getUserDetails() -> User? {
        guard let params = authStateRepository.state?.lastTokenResponse?.idToken?.parsedJWT else {
            return nil
        }
        if let idValue = params["sub"] as? String,
           let email = params["email"] as? String {
            let givenName = params["given_name"] as? String
            let familyName = params["family_name"] as? String
            let picture = params["picture"] as? String
            return User(id: idValue,
                        email: email,
                        lastName: familyName,
                        firstName: givenName,
                        picture: picture)
        }
        return nil
    }
    

    public func getClaim(forKey key: String, token: TokenType = .accessToken) -> Claim? {
        let lastTokenResponse = authStateRepository.state?.lastTokenResponse
        let tokenToParse = token == .accessToken ? lastTokenResponse?.accessToken: lastTokenResponse?.idToken
        guard let params = tokenToParse?.parsedJWT else {
            return nil
        }
        if let value = params[key],
            let value {
            return Claim(name: key, value: value)
        }
        return nil
    }
    
    @available(*, deprecated, message: "Use getClaim(forKey:token:) with return type Claim?")
    public func getClaim(key: String, token: TokenType = .accessToken) -> Any? {
        let lastTokenResponse = authStateRepository.state?.lastTokenResponse
        let tokenToParse = token == .accessToken ? lastTokenResponse?.accessToken: lastTokenResponse?.idToken
        guard let params = tokenToParse?.parsedJWT else {
            return nil
        }
        return params[key] ?? nil
    }
    
    public func getPermissions() -> Permissions? {
        if let permissionsClaim = getClaim(forKey: ClaimKey.permissions.rawValue),
           let permissionsArray = permissionsClaim.value as? [String],
           let orgCodeClaim = getClaim(forKey: ClaimKey.organisationCode.rawValue),
           let orgCode = orgCodeClaim.value as? String {
            
            let organization = Organization(code: orgCode)
            let permissions = Permissions(organization: organization,
                                          permissions: permissionsArray)
            return permissions
        }
        return nil
    }
    
    public func getPermission(name: String) -> Permission? {
        if let permissionsClaim = getClaim(forKey: ClaimKey.permissions.rawValue),
           let permissionsArray = permissionsClaim.value as? [String],
           let orgCodeClaim = getClaim(forKey: ClaimKey.organisationCode.rawValue),
           let orgCode = orgCodeClaim.value as? String {
            
            let organization = Organization(code: orgCode)
            let permission = Permission(organization: organization,
                                        isGranted: permissionsArray.contains(name))
            return permission
        }
        return nil
    }
    
    public func getOrganization() -> Organization? {
        if let orgCodeClaim = getClaim(forKey: ClaimKey.organisationCode.rawValue),
           let orgCode = orgCodeClaim.value as? String {
            let org = Organization(code: orgCode)
            return org
        }
        return nil
    }
    
    public func getUserOrganizations() -> UserOrganizations? {
        if let userOrgsClaim = getClaim(forKey: ClaimKey.organisationCodes.rawValue,
                                   token: .idToken),
           let userOrgs = userOrgsClaim.value as? [String] {
            
            let orgCodes = userOrgs.map({ Organization(code: $0)})
            return UserOrganizations(orgCodes: orgCodes)
        }
        return nil
    }
    
    private func getViewController() async -> UIViewController? {
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
    public func register(orgCode: String = "",
                         _ completion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            do {
                try await register(orgCode: orgCode)
                await MainActor.run(body: {
                    completion(.success(true))
                })
            } catch {
                await MainActor.run(body: {
                    completion(.failure(error))
                })
            }
        }
    }
    
    public func register(orgCode: String = "") async throws -> () {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                guard let viewController = await getViewController() else {
                    continuation.resume(throwing: AuthError.notAuthenticated)
                    return
                }
                do {
                    let request = try await getAuthorizationRequest(signUp: true, orgCode: orgCode)
                    _ = try await runCurrentAuthorizationFlow(request: request, viewController: viewController)
                    continuation.resume(with: .success(()))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Login an existing user
    ///
    @available(*, renamed: "login")
    public func login(orgCode: String = "",
                      _ completion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            do {
                try await login(orgCode: orgCode)
                await MainActor.run(body: {
                    completion(.success(true))
                })
            } catch {
                await MainActor.run(body: {
                    completion(.failure(error))
                })
            }
        }
    }

    public func login(orgCode: String = "") async throws -> () {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                guard let viewController = await getViewController() else {
                    continuation.resume(throwing: AuthError.notAuthenticated)
                    return
                }
                do {
                    let request = try await getAuthorizationRequest(signUp: false, orgCode: orgCode)
                    _ = try await runCurrentAuthorizationFlow(request: request, viewController: viewController)
                    continuation.resume(with: .success(()))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
        
    /// Register a new organization
    ///
    @available(*, renamed: "createOrg")
    public func createOrg( _ completion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            do {
                try await createOrg()
                await MainActor.run(body: {
                    completion(.success(true))
                })
            } catch {
                await MainActor.run(body: {
                    completion(.failure(error))
                })
            }
        }
    }

    public func createOrg() async throws -> () {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                guard let viewController = await getViewController() else {
                    continuation.resume(throwing: AuthError.notAuthenticated)
                    return
                }
                do {
                    let request = try await getAuthorizationRequest(signUp: true, createOrg: true)
                    _ = try await runCurrentAuthorizationFlow(request: request, viewController: viewController)
                    continuation.resume(with: .success(()))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Logout the current user
    @available(*, renamed: "logout()")
    public func logout(_ completion: @escaping (_ result: Bool) -> Void) {
        Task {
            let result = await logout()
            await MainActor.run {
                completion(result)
            }
        }
    }
    
    public func logout() async -> Bool {
        // There is no logout endpoint configured; simply clear the local auth state
        let cleared = authStateRepository.clear()
        return cleared
    }
    
    /// Create an Authorization Request using the configured Issuer and Redirect URLs,
    /// and OpenIDConnect configuration discovery
    @available(*, renamed: "getAuthorizationRequest(signUp:createOrg:orgCode:usePKCE:useNonce:)")
    private func getAuthorizationRequest(signUp: Bool,
                                         createOrg: Bool = false,
                                         orgCode: String = "",
                                         usePKCE: Bool = true,
                                         useNonce: Bool = false,
                                         then completion: @escaping (Result<OIDAuthorizationRequest, Error>) -> Void) {
        Task {
            do {
                let request = try await self.getAuthorizationRequest(signUp: signUp, createOrg: createOrg, orgCode: orgCode, usePKCE: usePKCE, useNonce: useNonce)
                completion(.success(request))
            } catch {
                completion(.failure(AuthError.notAuthenticated))
            }
        }
    }
    
    private func getAuthorizationRequest(signUp: Bool,
                                         createOrg: Bool = false,
                                         orgCode: String = "",
                                         usePKCE: Bool = true,
                                         useNonce: Bool = false) async throws -> OIDAuthorizationRequest {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                let issuerUrl = config.getIssuerUrl()
                guard let issuerUrl = issuerUrl else {
                    logger.error(message: "Failed to get issuer URL")
                    continuation.resume(throwing: AuthError.configuration)
                    return
                }
                do {
                    let result = try await discoverConfiguration(issuerUrl: issuerUrl,
                                                                 signUp: signUp,
                                                                 createOrg: createOrg,
                                                                 orgCode: orgCode,
                                                                 usePKCE: usePKCE,
                                                                 useNonce: useNonce)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func runCurrentAuthorizationFlow(request: OIDAuthorizationRequest, viewController: UIViewController) async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                await MainActor.run {
                    currentAuthorizationFlow = OIDAuthState.authState(byPresenting: request,
                                                                      presenting: viewController,
                                                                      prefersEphemeralSession: privateAuthSession,
                                                                      callback: authorizationFlowCallback(then: { value in
                        switch value {
                        case .success:
                            continuation.resume(returning: true)
                        case .failure(let error):
                            continuation.resume(throwing: error)
                        }
                    }))
                }
            }
        }
    }
    
    private func discoverConfiguration(issuerUrl: URL,
                                              signUp: Bool,
                                              createOrg: Bool = false,
                                              orgCode: String = "",
                                              usePKCE: Bool = true,
                                              useNonce: Bool = false) async throws -> (OIDAuthorizationRequest) {
        return try await withCheckedThrowingContinuation { continuation in
            OIDAuthorizationService.discoverConfiguration(forIssuer: issuerUrl) { configuration, error in
                if let error = error {
                    self.logger.error(message: "Failed to discover OpenID configuration: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
                
                guard let configuration = configuration else {
                    self.logger.error(message: "Failed to discover OpenID configuration")
                    continuation.resume(throwing: AuthError.configuration)
                    return
                }
                
                let redirectUrl = self.config.getRedirectUrl()
                guard let redirectUrl = redirectUrl else {
                    self.logger.error(message: "Failed to get redirect URL")
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
                
                if let audience = self.config.audience, !audience.isEmpty {
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
                
                continuation.resume(returning: request)
            }
        }
    }
    
    /// Callback to complete the current authorization flow
    private func authorizationFlowCallback(then completion: @escaping (Result<Bool, Error>) -> Void) -> (OIDAuthState?, Error?) -> Void {
        return { authState, error in
            if let error = error {
                self.logger.error(message: "Failed to finish authentication flow: \(error.localizedDescription)")
                _ = self.authStateRepository.clear()
                return completion(.failure(error))
            }
            
            guard let authState = authState else {
                self.logger.error(message: "Failed to get authentication state")
                _ = self.authStateRepository.clear()
                return completion(.failure(AuthError.notAuthenticated))
            }
            
            self.logger.debug(message: "Got authorization tokens. Access token: " +
                          "\(authState.lastTokenResponse?.accessToken ?? "nil")")
            
            let saved = self.authStateRepository.setState(authState)
            if !saved {
                return completion(.failure(AuthError.failedToSaveState))
            }
            
            self.currentAuthorizationFlow = nil
            completion(.success(true))
        }
    }
    
    /// Is the given error the result of user cancellation of an authorization flow
    public func isUserCancellationErrorCode(_ error: Error) -> Bool {
        let error = error as NSError
        return error.domain == OIDGeneralErrorDomain && error.code == OIDErrorCode.userCanceledAuthorizationFlow.rawValue
    }
    
    /// Perform an action, such as an API call, with a valid access token and ID token
    /// Failure to get a valid access token may require reauthentication
    @available(*, renamed: "performWithFreshTokens()")
    func performWithFreshTokens(_ action: @escaping (Result<Tokens, Error>) -> Void) {
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

    func performWithFreshTokens() async throws -> Tokens? {
        guard let authState = authStateRepository.state else {
            self.logger.error(message: "Failed to get authentication state")
            return nil
        }
        
        let params = ["Kinde-SDK": "Swift/\(SDKVersion.versionString)"]
        return try await withCheckedThrowingContinuation { continuation in
            authState.performAction(freshTokens: { (accessToken, idToken, error1) in
                if let error = error1 {
                    self.logger.error(message: "Failed to get authentication tokens: \(error.localizedDescription)")
                    return continuation.resume(with: .failure(error))
                }
                
                guard let accessToken1 = accessToken else {
                    self.logger.error(message: "Failed to get access token")
                    return continuation.resume(with: .failure(AuthError.notAuthenticated))
                }
                let tokens = Tokens(accessToken: accessToken1, idToken: idToken)
                continuation.resume(with: .success(tokens))
            }, additionalRefreshParameters: params)
        }
    }
    
    /// Return the access token with auto-refresh mechanism.
    /// - Returns: Returns access token, throw error if failed to refresh which may require re-authentication.
    public func getToken() async throws -> String {
        do {
            if let tokens = try await performWithFreshTokens() {
                return tokens.accessToken
            }else {
                throw AuthError.notAuthenticated
            }
        }catch {
            throw AuthError.notAuthenticated
        }
    }
}

// MARK: - Feature Flags
extension Auth {
    
    public func getFlag(code: String, defaultValue: Any? = nil, flagType: Flag.ValueType? = nil) throws -> Flag {
        return try getFlagInternal(code: code, defaultValue: defaultValue, flagType: flagType)
    }
    
    // Wrapper Methods
    
    public func getBooleanFlag(code: String, defaultValue: Bool? = nil) throws -> Bool {
        if let value = try getFlag(code: code, defaultValue: defaultValue, flagType: .bool).value as? Bool {
            return value
        }else {
            if let defaultValue = defaultValue {
                return defaultValue
            }else {
                throw FlagError.notFound
            }
        }
    }
    
    public func getStringFlag(code: String, defaultValue: String? = nil) throws -> String {
        if let value = try getFlag(code: code, defaultValue: defaultValue, flagType: .string).value as? String {
           return value
        }else{
            if let defaultValue = defaultValue {
                return defaultValue
            }else {
                throw FlagError.notFound
            }
        }
    }
    
    public func getIntegerFlag(code: String, defaultValue: Int? = nil) throws -> Int {
        if let value = try getFlag(code: code, defaultValue: defaultValue, flagType: .int).value as? Int {
            return value
        }else {
            if let defaultValue = defaultValue {
                return defaultValue
            }else {
                throw FlagError.notFound
            }
        }
    }
    
    // Internal
    
    private func getFlagInternal(code: String, defaultValue: Any?, flagType: Flag.ValueType?) throws -> Flag {
        
        guard let featureFlagsClaim = getClaim(forKey: ClaimKey.featureFlags.rawValue) else {
            throw FlagError.unknownError
        }
        
        guard let featureFlags = featureFlagsClaim.value as? [String : Any] else {
            throw FlagError.unknownError
        }
        
        if let flagData = featureFlags[code] as? [String: Any],
           let valueTypeLetter = flagData["t"] as? String,
           let actualFlagType = Flag.ValueType(rawValue: valueTypeLetter),
           let actualValue = flagData["v"] {
            
            // Value type check
            if let flagType, flagType != actualFlagType {
                throw FlagError.incorrectType("Flag \"\(code)\" is type \(actualFlagType.typeDescription) - requested type \(flagType.typeDescription)")
            }
            
            return Flag(code: code, type: actualFlagType, value: actualValue)
            
        }else {
            
            if let defaultValue = defaultValue {
                // This flag does not exist - default value provided
                return Flag(code: code, type: nil, value: defaultValue, isDefault: true)
            }else {
                throw FlagError.notFound
            }
        }
    }
}


extension Auth {
    /// Hide/Show message prompt in authentication sessions.
    public func enablePrivateAuthSession(_ isEnable: Bool) {
        privateAuthSession = isEnable
    }
}

extension Auth {
    private enum ClaimKey: String {
        case permissions = "permissions"
        case organisationCode = "org_code"
        case organisationCodes = "org_codes"
        case featureFlags = "feature_flags"
    }
}

public struct Claim {
    public let name: String
    public let value: Any
}

public struct Flag {
    public let code: String
    public let type: ValueType?
    public let value: Any
    public let isDefault: Bool

    public init(code: String, type: ValueType?, value: Any, isDefault: Bool = false) {
        self.code = code
        self.type = type
        self.value = value
        self.isDefault = isDefault
    }
    
    public enum ValueType: String {
        case string = "s"
        case int = "i"
        case bool = "b"
        
        fileprivate var typeDescription: String {
            switch self {
            case .string: return "string"
            case .bool: return "boolean"
            case .int: return "integer"
            }
        }
    }
}

public struct Organization {
    public let code: String
}

public struct Permission {
    public let organization: Organization
    public let isGranted: Bool
}

public struct Permissions {
    public let organization: Organization
    public let permissions: [String]
}

public struct UserOrganizations {
    public let orgCodes: [Organization]
}
