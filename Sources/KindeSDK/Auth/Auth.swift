import AppAuth
import os.log
#if canImport(UIKit)
import UIKit
#endif

/// The Kinde authentication service
@available(iOS 13.0, *)
public final class Auth {
    @Atomic private var currentAuthorizationFlow: OIDExternalUserAgentSession?
    
    private let config: Config
    private let authStateRepository: AuthStateRepository
    private let logger: LoggerProtocol
    private var privateAuthSession: Bool = false
    
    // MARK: - Service Properties
    
    /// Claims service for accessing user claims from tokens
    public lazy var claims: ClaimsService = ClaimsService(auth: self, logger: logger)
    
    /// Entitlements service for managing user entitlements
    public lazy var entitlements: EntitlementsService = EntitlementsService(auth: self, logger: logger)
    
    /// Feature flags service for managing feature flags
    public lazy var featureFlags: FeatureFlagsService = FeatureFlagsService(auth: self, logger: logger)
    
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
        if let valueOrNil = params[key],
            let value = valueOrNil {
            return Claim(name: key, value: AnyCodable(value))
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
        if !params.keys.contains(key) {
            os_log("The claimed value of \"%@\" does not exist in your token", log: .default, type: .error, key)
        }
        return params[key] ?? nil
    }
    
    public func getPermissions(options: ApiOptions) async throws -> Permissions {
        if options.forceApi {
            let response = try await PermissionsAPI.getPermissions()
            guard response.success, let data = response.data else {
                throw NSError(domain: "KindeSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch permissions from API - check network and authentication"])
            }
            let orgCode = data.orgCode ?? ""
            let organization = Organization(code: orgCode)
            return Permissions(organization: organization, permissions: response.getPermissionKeys())
        } else {
            guard let permissions = getPermissions() else {
                throw NSError(domain: "KindeSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Permissions not found in token claims"])
            }
            return permissions
        }
    }
    
    /// Get all permissions for the authenticated user (synchronous version, reads from token claims)
    /// - Returns: Permissions if found, nil otherwise
    public func getPermissions() -> Permissions? {
        if let permissionsClaim = getClaim(forKey: ClaimKey.permissions.rawValue),
           let permissionsArray = permissionsClaim.value.value as? [String],
           let orgCodeClaim = getClaim(forKey: ClaimKey.organisationCode.rawValue),
           let orgCode = orgCodeClaim.value.value as? String {
            
            let organization = Organization(code: orgCode)
            let permissions = Permissions(organization: organization,
                                          permissions: permissionsArray)
            return permissions
        }
        return nil
    }
    
    public func getPermission(name: String, options: ApiOptions) async throws -> Permission {
        if options.forceApi {
            let perms = try await getPermissions(options: options)
            return Permission(organization: perms.organization, isGranted: perms.permissions.contains(name))
        } else {
            guard let permission = getPermission(name: name) else {
                throw NSError(domain: "KindeSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Permission not found in token claims"])
            }
            return permission
        }
    }
    
    /// Check if user has a specific permission (synchronous version, reads from token claims)
    /// - Parameter name: The permission name to check
    /// - Returns: Permission if found, nil otherwise
    public func getPermission(name: String) -> Permission? {
        if let permissionsClaim = getClaim(forKey: ClaimKey.permissions.rawValue),
           let permissionsArray = permissionsClaim.value.value as? [String],
           let orgCodeClaim = getClaim(forKey: ClaimKey.organisationCode.rawValue),
           let orgCode = orgCodeClaim.value.value as? String {
            
            let organization = Organization(code: orgCode)
            let permission = Permission(organization: organization,
                                        isGranted: permissionsArray.contains(name))
            return permission
        }
        return nil
    }
    
    public func getRoles(options: ApiOptions) async throws -> Roles {
        if options.forceApi {
            let response = try await RolesAPI.getRoles()
            guard response.success, let data = response.data else {
                throw NSError(domain: "KindeSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch roles from API - check network and authentication"])
            }
            let orgCode = data.orgCode ?? ""
            let organization = Organization(code: orgCode)
            return Roles(organization: organization, roles: response.getRoleKeys())
        } else {
            guard let roles = getRoles() else {
                throw NSError(domain: "KindeSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Roles not found in token claims"])
            }
            return roles
        }
    }
    
    /// Get all roles for the authenticated user (synchronous version, reads from token claims)
    /// - Returns: Roles if found, nil otherwise
    public func getRoles() -> Roles? {
        if let rolesClaim = getClaim(forKey: ClaimKey.roles.rawValue),
           let rolesArray = rolesClaim.value.value as? [String],
           let orgCodeClaim = getClaim(forKey: ClaimKey.organisationCode.rawValue),
           let orgCode = orgCodeClaim.value.value as? String {
            
            let organization = Organization(code: orgCode)
            let roles = Roles(organization: organization,
                             roles: rolesArray)
            return roles
        }
        return nil
    }
    
    public func getRole(name: String, options: ApiOptions) async throws -> Role {
        if options.forceApi {
            let roles = try await getRoles(options: options)
            return Role(organization: roles.organization, isGranted: roles.roles.contains(name))
        } else {
            guard let role = getRole(name: name) else {
                throw NSError(domain: "KindeSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Role not found in token claims"])
            }
            return role
        }
    }
    
    /// Check if user has a specific role (synchronous version, reads from token claims)
    /// - Parameter name: The role name to check
    /// - Returns: Role if found, nil otherwise
    public func getRole(name: String) -> Role? {
        if let rolesClaim = getClaim(forKey: ClaimKey.roles.rawValue),
           let rolesArray = rolesClaim.value.value as? [String],
           let orgCodeClaim = getClaim(forKey: ClaimKey.organisationCode.rawValue),
           let orgCode = orgCodeClaim.value.value as? String {
            
            let organization = Organization(code: orgCode)
            let role = Role(organization: organization,
                           isGranted: rolesArray.contains(name))
            return role
        }
        return nil
    }
    
    public func getOrganization() -> Organization? {
        if let orgCodeClaim = getClaim(forKey: ClaimKey.organisationCode.rawValue),
           let orgCode = orgCodeClaim.value.value as? String {
            let org = Organization(code: orgCode)
            return org
        }
        return nil
    }
    
    public func getUserOrganizations() -> UserOrganizations? {
        if let userOrgsClaim = getClaim(forKey: ClaimKey.organisationCodes.rawValue,
                                   token: .idToken),
           let userOrgs = userOrgsClaim.value.value as? [String] {
            
            let orgCodes = userOrgs.map({ Organization(code: $0)})
            return UserOrganizations(orgCodes: orgCodes)
        }
        return nil
    }
    
    #if canImport(UIKit)
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
    #else
    private func getViewController() async -> Any? {
        return nil
    }
    #endif
    
    /// Register a new user
    ///
    @available(*, renamed: "register")
    public func register(orgCode: String = "", loginHint: String = "", planInterest: String = "", pricingTableKey: String = "",
                         _ completion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            do {
                try await register(orgCode: orgCode, loginHint: loginHint, planInterest: planInterest, pricingTableKey: pricingTableKey)
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
    
    public func register(orgCode: String = "", loginHint: String = "", planInterest: String = "", pricingTableKey: String = "") async throws -> () {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                guard let viewController = await self.getViewController() else {
                    continuation.resume(throwing: AuthError.notAuthenticated)
                    return
                }
                do {
                    let request = try await self.getAuthorizationRequest(signUp: true, orgCode: orgCode, loginHint: loginHint, planInterest: planInterest, pricingTableKey: pricingTableKey)
                    _ = try await self.runCurrentAuthorizationFlow(request: request, viewController: viewController)
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
    public func login(orgCode: String = "", loginHint: String = "",
                      _ completion: @escaping (Result<Bool, Error>) -> Void) {
        Task {
            do {
                try await login(orgCode: orgCode, loginHint: loginHint)
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

    public func login(orgCode: String = "", loginHint: String = "") async throws -> () {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                guard let viewController = await self.getViewController() else {
                    continuation.resume(throwing: AuthError.notAuthenticated)
                    return
                }
                do {
                    let request = try await self.getAuthorizationRequest(signUp: false, orgCode: orgCode, loginHint: loginHint)
                    _ = try await self.runCurrentAuthorizationFlow(request: request, viewController: viewController)
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

    public func createOrg(orgName: String = "") async throws -> () {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                guard let viewController = await self.getViewController() else {
                    continuation.resume(throwing: AuthError.notAuthenticated)
                    return
                }
                do {
                    let request = try await self.getAuthorizationRequest(signUp: true, createOrg: true, orgName: orgName)
                    _ = try await self.runCurrentAuthorizationFlow(request: request, viewController: viewController)
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
                                         loginHint: String = "",
                                         orgName: String = "",
                                         usePKCE: Bool = true,
                                         useNonce: Bool = false,
                                         planInterest: String = "",
                                         pricingTableKey: String = "") async throws -> OIDAuthorizationRequest {
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
                                                                 loginHint: loginHint,
                                                                 orgName: orgName,
                                                                 usePKCE: usePKCE,
                                                                 useNonce: useNonce,
                                                                 planInterest: planInterest,
                                                                 pricingTableKey: pricingTableKey)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    #if canImport(UIKit)
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
    #else
    private func runCurrentAuthorizationFlow(request: OIDAuthorizationRequest, viewController: Any) async throws -> Bool {
        throw AuthError.notAuthenticated
    }
    #endif
    
    private func discoverConfiguration(issuerUrl: URL,
                                              signUp: Bool,
                                              createOrg: Bool = false,
                                              orgCode: String = "",
                                              loginHint: String = "",
                                              orgName: String = "",
                                              usePKCE: Bool = true,
                                              useNonce: Bool = false,
                                              planInterest: String = "",
                                              pricingTableKey: String = "") async throws -> (OIDAuthorizationRequest) {
        return try await withCheckedThrowingContinuation { continuation in
            OIDAuthorizationService.discoverConfiguration(forIssuer: issuerUrl) { configuration, error in
                if let error = error {
                    self.logger.error(message: "Failed to discover OpenID configuration: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
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
                
                if !orgName.isEmpty {
                    additionalParameters["org_name"] = orgName
                }

                if !loginHint.isEmpty {
                    additionalParameters["login_hint"] = loginHint
                }
                
                if !planInterest.isEmpty {
                    additionalParameters["plan_interest"] = planInterest
                }

                if !pricingTableKey.isEmpty {
                    additionalParameters["pricing_table_key"] = pricingTableKey
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
    
    func extractEmail(from idToken: String) -> String? {
        let params = idToken.parsedJWT
        return params["email"] as? String
    }
    
    func hasMatchingEmail(in authState: OIDAuthState) -> Bool {
        guard let currentIDToken = authState.lastTokenResponse?.idToken,
              let existingIDToken = self.authStateRepository.state?.lastTokenResponse?.idToken,
              let currentEmail = extractEmail(from: currentIDToken),
              let existingEmail = extractEmail(from: existingIDToken)
        else { return false }
        return currentEmail == existingEmail
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
            
            let shouldPreserveState = self.isAuthenticated() && self.hasMatchingEmail(in: authState)
            let saved = shouldPreserveState ? true : self.authStateRepository.setState(authState)
            
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
    
    /// Return the desired token with auto-refresh mechanism.
    /// - Returns: Returns either the access token (default) or the id token, throw error if failed to refresh which may require re-authentication.
    public func getToken(desiredToken: TokenType = .accessToken) async throws -> String {
        do {
            if let tokens = try await performWithFreshTokens() {
                if let token = (desiredToken == .accessToken ? tokens.accessToken : tokens.idToken) {
                    return token
                } else {
                    throw AuthError.notAuthenticated
                }
            } else {
                throw AuthError.notAuthenticated
            }
        } catch {
            throw AuthError.notAuthenticated
        }
    }
    
    public func getToken() async throws -> Tokens {
        do {
            if let tokens = try await performWithFreshTokens() {
                return Tokens(accessToken: tokens.accessToken, idToken: tokens.idToken)
            } else {
                throw AuthError.notAuthenticated
            }
        } catch {
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
    
    public func getBooleanFlag(code: String, defaultValue: Bool? = nil, options: ApiOptions) async throws -> Bool? {
        if options.forceApi {
            let response = try await FeatureFlagsAPI.getFeatureFlags()
            guard response.success else {
                throw NSError(domain: "KindeSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Feature flags API returned success: false"])
            }
            let flags = response.toFlagMap()
            let flag = flags[code]
            if let flag = flag, let boolValue = flag.value as? Bool {
                return boolValue
            } else {
                return defaultValue
            }
        } else {
            do {
                return try getBooleanFlag(code: code, defaultValue: defaultValue)
            } catch {
                return defaultValue
            }
        }
    }
    
    /// Get a boolean feature flag value (synchronous version, reads from token claims)
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
    
    public func getStringFlag(code: String, defaultValue: String? = nil, options: ApiOptions) async throws -> String? {
        if options.forceApi {
            let response = try await FeatureFlagsAPI.getFeatureFlags()
            guard response.success else {
                throw NSError(domain: "KindeSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Feature flags API returned success: false"])
            }
            let flags = response.toFlagMap()
            let flag = flags[code]
            if let flag = flag, let stringValue = flag.value as? String {
                return stringValue
            } else {
                return defaultValue
            }
        } else {
            do {
                return try getStringFlag(code: code, defaultValue: defaultValue)
            } catch {
                return defaultValue
            }
        }
    }
    
    /// Get a string feature flag value (synchronous version, reads from token claims)
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
    
    public func getIntegerFlag(code: String, defaultValue: Int? = nil, options: ApiOptions) async throws -> Int? {
        if options.forceApi {
            let response = try await FeatureFlagsAPI.getFeatureFlags()
            guard response.success else {
                throw NSError(domain: "KindeSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Feature flags API returned success: false"])
            }
            let flags = response.toFlagMap()
            let flag = flags[code]
            if let flag = flag, let intValue = flag.value as? Int {
                return intValue
            } else if let flag = flag, let numberValue = flag.value as? NSNumber {
                return numberValue.intValue
            } else {
                return defaultValue
            }
        } else {
            do {
                return try getIntegerFlag(code: code, defaultValue: defaultValue)
            } catch {
                return defaultValue
            }
        }
    }
    
    /// Get an integer feature flag value (synchronous version, reads from token claims)
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
    
    /// Get all feature flags for the authenticated user
    /// - Parameter options: Optional API options. Use ApiOptions(forceApi: true) to fetch fresh data from API
    /// - Returns: Map of flag codes to Flag objects
    public func getAllFlags(options: ApiOptions? = nil) async throws -> [String: Flag] {
        if options?.forceApi == true {
            let response = try await FeatureFlagsAPI.getFeatureFlags()
            guard response.success else {
                throw NSError(domain: "KindeSDK", code: -1, userInfo: [NSLocalizedDescriptionKey: "Feature flags API returned success: false"])
            }
            return response.toFlagMap()
        } else {
            guard let featureFlagsClaim = getClaim(forKey: ClaimKey.featureFlags.rawValue),
                  let featureFlags = featureFlagsClaim.value.value as? [String: Any] else {
                return [:]
            }
            
            var flagMap: [String: Flag] = [:]
            for (code, flagData) in featureFlags {
                if let flagDict = flagData as? [String: Any],
                   let valueTypeLetter = flagDict["t"] as? String,
                   let flagType = Flag.ValueType(rawValue: valueTypeLetter),
                   let value = flagDict["v"] {
                    flagMap[code] = Flag(code: code, type: flagType, value: value, isDefault: false)
                }
            }
            return flagMap
        }
    }
    
    // Internal
    
    private func getFlagInternal(code: String, defaultValue: Any?, flagType: Flag.ValueType?) throws -> Flag {
        
        // If no feature_flags claim exists, check if default value is provided
        guard let featureFlagsClaim = getClaim(forKey: ClaimKey.featureFlags.rawValue) else {
            if let defaultValue = defaultValue {
                // Default value provided - return it even if claim doesn't exist
                return Flag(code: code, type: nil, value: defaultValue, isDefault: true)
            } else {
                throw FlagError.unknownError
            }
        }
        
        guard let featureFlags = featureFlagsClaim.value as? [String : Any] else {
            // Claim exists but is not a dictionary - check for default value
            if let defaultValue = defaultValue {
                return Flag(code: code, type: nil, value: defaultValue, isDefault: true)
            } else {
                throw FlagError.unknownError
            }
        }
        
        if let flagData = featureFlags[code] as? [String: Any],
           let valueTypeLetter = flagData["t"] as? String,
           let actualFlagType = Flag.ValueType(rawValue: valueTypeLetter),
           let actualValue = flagData["v"] {
            
            // Value type check
            if let flagType = flagType,
                flagType != actualFlagType {
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
    
    /// Get the current token response
    /// - Returns: The current token response if available
    public func getTokenResponse() -> OIDTokenResponse? {
        return authStateRepository.state?.lastTokenResponse
    }
}


/// Service for managing JWT claims with type-safe API
@available(iOS 13.0, *)
public class ClaimsService {
    private unowned let auth: Auth
    private let logger: LoggerProtocol
    
    public init(auth: Auth, logger: LoggerProtocol = DefaultLogger()) {
        self.auth = auth
        self.logger = logger
    }
    
    /// Get a specific claim by key
    /// - Parameter key: The claim key to retrieve
    /// - Returns: Claim if found, nil otherwise
    public func getClaim(forKey key: String) -> Claim? {
        return auth.getClaim(forKey: key)
    }
    
    /// Check if a specific permission is granted
    /// - Parameter name: The permission name to check
    /// - Returns: True if permission is granted, false otherwise
    public func getPermission(name: String) -> Bool {
        return auth.getPermission(name: name)?.isGranted ?? false
    }
    
    /// Get all roles for the current user
    /// - Returns: Roles if found, nil otherwise
    public func getRoles() -> Roles? {
        return auth.getRoles()
    }
    
    /// Check if user has a specific role
    /// - Parameter name: The role name to check
    /// - Returns: Role if found, nil otherwise
    public func getRole(name: String) -> Role? {
        return auth.getRole(name: name)
    }
    
    /// Get the raw value of a claim by key
    /// - Parameter key: The claim key to retrieve
    /// - Returns: The claim value if found, nil otherwise
    public func getClaimValue(forKey key: String) -> Any? {
        guard let claim = getClaim(forKey: key) else {
            return nil
        }
        return claim.value.value
    }
}

/// Service for managing user entitlements with type-safe API
@available(iOS 13.0, *)
public class EntitlementsService {
    private unowned let auth: Auth
    private let logger: LoggerProtocol
    
    public init(auth: Auth, logger: LoggerProtocol = DefaultLogger()) {
        self.auth = auth
        self.logger = logger
    }
    
    /// Get all entitlements for the current user
    /// - Returns: Dictionary of entitlements with their values, or empty dictionary if not available
    public func getEntitlements() -> [String: Any] {
        guard let claim = auth.claims.getClaim(forKey: "entitlements") else {
            return [:]
        }
        
        let rawValue = claim.value.value
        
        // Try to parse as JSON string first
        if let claimString = rawValue as? String,
           let data = claimString.data(using: .utf8) {
            do {
                let entitlements = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                return entitlements ?? [:]
            } catch {
                logger.error(message: "Failed to parse entitlements JSON: \(error)")
            }
        }
        
        // Try to parse as direct dictionary
        if let entitlementsDict = rawValue as? [String: Any] {
            return entitlementsDict
        }
        
        return [:]
    }
    
    /// Get a specific entitlement by feature key
    /// - Parameter featureKey: The feature key to look for
    /// - Returns: Entitlement value if found, nil otherwise
    public func getEntitlement(featureKey: String) -> Any? {
        let entitlements = getEntitlements()
        return entitlements[featureKey]
    }
    
    /// Check if user has a specific entitlement
    /// - Parameter featureKey: The feature key to check
    /// - Returns: True if user has the entitlement, false otherwise
    public func hasEntitlement(featureKey: String) -> Bool {
        return getEntitlement(featureKey: featureKey) != nil
    }
    
    // MARK: - HTTP API Methods (Server-side Entitlements)
    
    /// Fetch entitlements from the server with pagination support
    /// - Parameters:
    ///   - pageSize: Number of results per page (optional)
    ///   - startingAfter: Token to get the next page of results (optional)
    /// - Returns: EntitlementsResponse with pagination metadata
    /// - Throws: AuthError if not authenticated or network error
    @available(iOS 15.0, *)
    public func fetchEntitlements(pageSize: Int? = nil, startingAfter: String? = nil) async throws -> EntitlementsResponse {
        guard auth.isAuthenticated() else {
            throw AuthError.notAuthenticated
        }
        
        let tokens = try await auth.getToken()
        let token = tokens.accessToken
        
        // Build URL with query parameters
        var urlComponents = URLComponents(string: "\(KindeSDKAPI.basePath)/account_api/v1/entitlements")
        var queryItems: [URLQueryItem] = []
        
        if let pageSize = pageSize {
            queryItems.append(URLQueryItem(name: "page_size", value: String(pageSize)))
        }
        
        if let startingAfter = startingAfter {
            queryItems.append(URLQueryItem(name: "starting_after", value: startingAfter))
        }
        
        urlComponents?.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let url = urlComponents?.url else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            logger.error(message: "Failed to fetch entitlements. Status: \(httpResponse.statusCode)")
            throw AuthError.serverError(httpResponse.statusCode)
        }
        
        do {
            let entitlementsResponse = try JSONDecoder().decode(EntitlementsResponse.self, from: data)
            return entitlementsResponse
        } catch {
            logger.error(message: "Failed to decode entitlements response: \(error)")
            throw AuthError.decodingError
        }
    }
    
    /// Fetch a single entitlement from the server
    /// - Returns: EntitlementResponse with the entitlement data
    /// - Throws: AuthError if not authenticated or network error
    @available(iOS 15.0, *)
    public func fetchEntitlement() async throws -> EntitlementResponse {
        guard auth.isAuthenticated() else {
            throw AuthError.notAuthenticated
        }
        
        let tokens = try await auth.getToken()
        let token = tokens.accessToken
        
        guard let url = URL(string: "\(KindeSDKAPI.basePath)/account_api/v1/entitlement") else {
            throw AuthError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            logger.error(message: "Failed to fetch entitlement. Status: \(httpResponse.statusCode)")
            throw AuthError.serverError(httpResponse.statusCode)
        }
        
        do {
            let entitlementResponse = try JSONDecoder().decode(EntitlementResponse.self, from: data)
            return entitlementResponse
        } catch {
            logger.error(message: "Failed to decode entitlement response: \(error)")
            throw AuthError.decodingError
        }
    }
    
    /// Get all entitlements from server (handles pagination automatically)
    /// - Returns: Array of all entitlements
    /// - Throws: AuthError if not authenticated or network error
    public func getAllEntitlements() async throws -> [Entitlement] {
        var allEntitlements: [Entitlement] = []
        var startingAfter: String? = nil
        
        repeat {
            let response = try await fetchEntitlements(startingAfter: startingAfter)
            allEntitlements.append(contentsOf: response.data.entitlements)
            startingAfter = response.metadata.nextPageStartingAfter
        } while startingAfter != nil
        
        return allEntitlements
    }
    
    /// Get entitlements as a dictionary (convenience method)
    /// - Returns: Dictionary of entitlements with their values
    /// - Throws: AuthError if not authenticated or network error
    public func getEntitlementsDictionary() async throws -> [String: Any] {
        let entitlements = try await getAllEntitlements()
        var dictionary: [String: Any] = [:]
        
        for entitlement in entitlements {
            dictionary[entitlement.key] = entitlement.value.value
        }
        
        return dictionary
    }
    
    // MARK: - Hard Check Methods
    
    /// Check if user has a boolean entitlement with hard check
    /// - Parameters:
    ///   - featureKey: The entitlement key to check
    ///   - defaultValue: Default value if entitlement not found (hard check)
    /// - Returns: Boolean entitlement value
    public func getBooleanEntitlement(featureKey: String, defaultValue: Bool = false) -> Bool {
        let entitlements = getEntitlements()
        if let value = entitlements[featureKey] {
            if let boolValue = value as? Bool {
                return boolValue
            } else if let stringValue = value as? String {
                return Bool(stringValue) ?? defaultValue
            }
        }
        return defaultValue
    }
    
    /// Check if user has a string entitlement with hard check
    /// - Parameters:
    ///   - featureKey: The entitlement key to check
    ///   - defaultValue: Default value if entitlement not found (hard check)
    /// - Returns: String entitlement value
    public func getStringEntitlement(featureKey: String, defaultValue: String = "") -> String {
        let entitlements = getEntitlements()
        if let value = entitlements[featureKey] {
            if let stringValue = value as? String {
                return stringValue
            } else {
                return String(describing: value)
            }
        }
        return defaultValue
    }
    
    /// Check if user has a numeric entitlement with hard check
    /// - Parameters:
    ///   - featureKey: The entitlement key to check
    ///   - defaultValue: Default value if entitlement not found (hard check)
    /// - Returns: Numeric entitlement value
    public func getNumericEntitlement(featureKey: String, defaultValue: Int = 0) -> Int {
        let entitlements = getEntitlements()
        if let value = entitlements[featureKey] {
            if let intValue = value as? Int {
                return intValue
            } else if let stringValue = value as? String {
                return Int(stringValue) ?? defaultValue
            }
        }
        return defaultValue
    }
    
    /// Perform a hard check with validation and fallback
    /// - Parameters:
    ///   - checkName: Name of the check being performed
    ///   - validation: Validation function that returns the result
    ///   - fallbackValue: Fallback value if validation fails
    /// - Returns: Result of validation or fallback value
    public func performHardCheck<T>(checkName: String, validation: () -> T?, fallbackValue: T) -> T {
        if let result = validation() {
            return result
        } else {
            logger.error(message: "Hard check '\(checkName)' failed, using fallback: \(fallbackValue)")
            return fallbackValue
        }
    }
    
    /// Validate a user permission with hard check
    /// - Parameters:
    ///   - permission: The permission name to validate
    ///   - fallbackAccess: Default access value if permission not found
    /// - Returns: True if permission is granted, fallback value otherwise
    public func validatePermission(permission: String, fallbackAccess: Bool) -> Bool {
        return performHardCheck(
            checkName: "permission:\(permission)",
            validation: { auth.getPermission(name: permission)?.isGranted },
            fallbackValue: fallbackAccess
        )
    }
    
    /// Validate a user role with hard check
    /// - Parameters:
    ///   - role: The role name to validate
    ///   - fallbackAccess: Default access value if role not found
    /// - Returns: True if user has the role, fallback value otherwise
    public func validateRole(role: String, fallbackAccess: Bool) -> Bool {
        return performHardCheck(
            checkName: "role:\(role)",
            validation: {
                auth.getRole(name: role)?.isGranted
            },
            fallbackValue: fallbackAccess
        )
    }
    
    /// Validate a feature flag with hard check
    /// - Parameters:
    ///   - flag: The feature flag code to validate
    ///   - fallbackEnabled: Default enabled value if flag not found
    /// - Returns: True if feature flag is enabled, fallback value otherwise
    public func validateFeatureFlag(flag: String, fallbackEnabled: Bool) -> Bool {
        return performHardCheck(
            checkName: "featureFlag:\(flag)",
            validation: {
                try? auth.getBooleanFlag(code: flag)
            },
            fallbackValue: fallbackEnabled
        )
    }
    
    /// Validate an entitlement with hard check
    /// - Parameters:
    ///   - entitlement: The entitlement key to validate
    ///   - fallbackValue: Default value if entitlement not found
    /// - Returns: Entitlement value if found, fallback value otherwise
    public func validateEntitlement(entitlement: String, fallbackValue: String) -> String {
        return performHardCheck(
            checkName: "entitlement:\(entitlement)",
            validation: {
                if let value = getEntitlement(featureKey: entitlement) {
                    return String(describing: value)
                }
                return nil
            },
            fallbackValue: fallbackValue
        )
    }
    
    /// Check if the user is authenticated
    /// - Returns: True if user is authenticated, false otherwise
    public func isUserAuthenticated() -> Bool {
        return auth.isAuthenticated()
    }
    
    /// Get user organization context
    /// - Returns: Dictionary with organization information, or empty dictionary if not available
    public func getUserOrganization() -> [String: Any] {
        guard let org = auth.getOrganization() else {
            return [:]
        }
        return ["code": org.code]
    }
    
    /// Get user subscription tier
    /// - Returns: Subscription tier string, defaults to "free" if not found
    public func getUserSubscriptionTier() -> String {
        return getStringEntitlement(featureKey: "subscription_tier", defaultValue: "free")
    }
}

/// Service for managing feature flags with type-safe API
@available(iOS 13.0, *)
public class FeatureFlagsService {
    private unowned let auth: Auth
    private let logger: LoggerProtocol
    
    public init(auth: Auth, logger: LoggerProtocol = DefaultLogger()) {
        self.auth = auth
        self.logger = logger
    }
    
    /// Get all feature flags for the current user
    /// - Returns: Dictionary of feature flags with their values, or empty dictionary if not available
    public func getFeatureFlags() -> [String: Any] {
        guard let claim = auth.claims.getClaim(forKey: "feature_flags") else {
            return [:]
        }
        
        let rawValue = claim.value.value
        
        // Try to parse as JSON string first
        if let claimString = rawValue as? String,
           let data = claimString.data(using: .utf8) {
            do {
                let flags = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                return flags ?? [:]
            } catch {
                logger.error(message: "Failed to parse feature flags JSON: \(error)")
            }
        }
        
        // Try to parse as direct dictionary
        if let flagsDict = rawValue as? [String: Any] {
            return flagsDict
        }
        
        return [:]
    }
    
    /// Get a specific feature flag by code
    /// - Parameter code: The feature flag code to look for
    /// - Returns: Feature flag value if found, nil otherwise
    public func getFeatureFlag(code: String) -> Any? {
        let flags = getFeatureFlags()
        return flags[code]
    }
    
    /// Check if a feature flag is enabled (boolean type)
    /// - Parameters:
    ///   - code: The feature flag code to check
    ///   - defaultValue: Default value if flag not found
    /// - Returns: Boolean indicating if feature is enabled
    public func isFeatureEnabled(code: String, defaultValue: Bool = false) -> Bool {
        guard let flagValue = getFeatureFlag(code: code) else {
            return defaultValue
        }
        
        // Handle boolean values
        if let boolValue = flagValue as? Bool {
            return boolValue
        }
        
        // Handle string values that represent booleans
        if let stringValue = flagValue as? String {
            return Bool(stringValue) ?? defaultValue
        }
        
        return defaultValue
    }
}

extension Auth {
    private enum ClaimKey: String {
        case permissions = "permissions"
        case roles = "roles"
        case organisationCode = "org_code"
        case organisationCodes = "org_codes"
        case featureFlags = "feature_flags"
    }
}
