import Foundation

public enum AuthError: Error {
    /// Failed to retrieve local or remote configuration
    case configuration
    /// Failed to obtain valid authentication state
    case notAuthenticated
    /// Failed to save authentication state on device
    case failedToSaveState
    /// Invalid URL for API request
    case invalidURL
    /// Invalid response from server
    case invalidResponse
    /// Server returned an error with status code
    case serverError(Int)
    /// Failed to decode response data
    case decodingError
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
        case .invalidURL:
            return NSLocalizedString(
                "Invalid URL for API request.",
                comment: "Invalid URL"
            )
        case .invalidResponse:
            return NSLocalizedString(
                "Invalid response from server.",
                comment: "Invalid Response"
            )
        case .serverError(let statusCode):
            return NSLocalizedString(
                "Server returned an error with status code: \(statusCode).",
                comment: "Server Error"
            )
        case .decodingError:
            return NSLocalizedString(
                "Failed to decode response data.",
                comment: "Decoding Error"
            )
        }
    }
}
