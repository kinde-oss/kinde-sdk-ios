import Foundation

/// Determines the page the user should land on.
public enum Prompt: String, Sendable {
    /// The user will land on the sign in page.
    case login
    
    /// The user will land on the sign up page to create an account.
    case create
    
    /// Kinde will not show authentication screens to the user.
    ///
    /// - If the user has an active SSO session, this will redirect them to the callback URL where the token exchange can occur.
    /// - If the user does NOT have an active SSO session, this will redirect them to the callback URL with a `login_required` error.
    case none
    
    /// The exact string value required by the Kinde API.
    ///
    /// This property is used instead of `rawValue` to decouple the internal Swift enum naming 
    /// from the external API contract. This prevents accidental breaking changes if the 
    /// enum cases are renamed.
    public var apiValue: String {
        switch self {
        case .login:
            return "login"
        case .create:
            return "create"
        case .none:
            return "none"
        }
    }
}
