import Foundation

/// Configuration for the Kinde authentication service and Kinde Management API client
public struct Config: Decodable {
    let issuer: String
    let clientId: String
    let redirectUri: String
    let postLogoutRedirectUri: String
    let scope: String
    let audience: String?
    
    public init(issuer: String, clientId: String, redirectUri: String,
                postLogoutRedirectUri: String, scope: String, audience: String?) {
        self.issuer = issuer
        self.clientId = clientId
        self.redirectUri = redirectUri
        self.postLogoutRedirectUri = postLogoutRedirectUri
        self.scope = scope
        self.audience = audience
    }
    
    /// Get the configured Issuer URL, or `nil` if it is missing or malformed
    public func getIssuerUrl() -> URL? {
        guard let url = URL(string: self.issuer) else {
            return nil
        }
        return url
    }
     
    /// Get the configured Redirect URL, or `nil` if it is missing or malformed
    func getRedirectUrl() -> URL? {
        guard let url = URL(string: self.redirectUri) else {
            return nil
        }
        return url
    }
    
    /// Get the configured Post Logout Redirect URL, or `nil` if it is missing or malformed
    func getPostLogoutRedirectUrl() -> URL? {
        guard let url = URL(string: self.postLogoutRedirectUri) else {
            return nil
        }
        return url
    }
    
    /// Load configuration from bundled source file: (default) `KindeAuth.plist` or `kinde-auth.json`
    /// If your app requires multiple configurations for development and production, add all Kinde configuration files to your app target and specify the desired configuration using `configurationFileName`
    
    static func initialize(configurationFileName: String = "kinde-auth") -> Config? {
        do {
            let normalizedFileName = configurationFileName.replacingOccurrences(of: ".json", with: "")
            var configFilePath: String = ""
            for bundle in Bundle.allBundles {
                if let resourcePath = bundle.path(forResource: normalizedFileName, ofType: "json") {
                    configFilePath = resourcePath
                    break
                }
            }
            let jsonString = try String(contentsOfFile: configFilePath)
            let jsonData = jsonString.data(using: .utf8) ?? Data()
            let decoder = JSONDecoder()
            let config = try decoder.decode(Config.self, from: jsonData)
            if URLComponents(string: config.issuer) != nil {
                return config
            } else {
                return loadFromPlist()
            }
        } catch {
            return loadFromPlist()
        }
    }
    
    private static func loadFromPlist() -> Config? {
        var configFilePath: String = ""
        for bundle in Bundle.allBundles {
            if let resourcePath = bundle.path(forResource: "KindeAuth", ofType: "plist") {
                configFilePath = resourcePath
                break
            }
        }
        guard configFilePath.count > 0,
              let values = NSDictionary(contentsOfFile: configFilePath) as? [String: Any] else {
                return nil
        }
        
        guard let issuer = values["Issuer"] as? String,
              let clientId = values["ClientId"] as? String,
              let redirectUri = values["RedirectUri"] as? String,
              let postLogoutRedirectUri = values["PostLogoutRedirectUri"] as? String,
              let scope = values["Scope"] as? String else {
                return nil
            }
        let audience = values["Audience"] as? String
        return Config(issuer: issuer,
                      clientId: clientId,
                      redirectUri: redirectUri,
                      postLogoutRedirectUri: postLogoutRedirectUri,
                      scope: scope,
                      audience: audience)
    }
}
