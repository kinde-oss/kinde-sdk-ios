import Foundation

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
