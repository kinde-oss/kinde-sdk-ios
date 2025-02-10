import Foundation

/// Authentication and identity tokens from the Kinde service
public struct Tokens {
    /// A bearer token for making authenticated calls to Kinde endpoints
    public var accessToken: String
    /// An ID token for the subject of the `accessToken`
    public var idToken: String?
}

public enum TokenType: String {
    case idToken
    case accessToken
}
