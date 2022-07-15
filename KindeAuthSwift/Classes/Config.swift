import Foundation

/// Configuration for the Kinde authentication service
public struct Config: Decodable {
    let issuer: String
    let clientId: String
    let redirectUri: String
    let postLogoutRedirectUri: String
    let scope: String
    
    public init(issuer: String, clientId: String, redirectUri: String, postLogoutRedirectUri: String, scope: String) {
        self.issuer = issuer
        self.clientId = clientId
        self.redirectUri = redirectUri
        self.postLogoutRedirectUri = postLogoutRedirectUri
        self.scope = scope
    }
    
    /// Get the configured Issuer URL, or `nil` if it is missing or malformed
    public func getIssuerUrl() -> URL? {
        guard let url = URL(string: self.issuer) else {
            return nil
        }
        return url
    }
    
    /// Get the configured Redirect URL, or `nil` if it is missing or malformed
    public func getRedirectUrl() -> URL? {
        guard let url = URL(string: self.redirectUri) else {
            return nil
        }
        return url
    }
    
    /// Get the configured Post Logout Redirect URL, or `nil` if it is missing or malformed
    public func getPostLogoutRedirectUrl() -> URL? {
        guard let url = URL(string: self.postLogoutRedirectUri) else {
            return nil
        }
        return url
    }
}
