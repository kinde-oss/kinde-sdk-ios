import Foundation

public enum FlagError: Error {
    /// Flag not found against a code.
    case notFound
    /// Feature Flags are unable to read.
    case unknownError
    /// Flag type is not correct.
    case incorrectType(String)
}

extension FlagError {
    public var errorDescription: String? {
        switch self {
        case .notFound:
            return NSLocalizedString(
                "This flag was not found, and no default value has been provided",
                comment: "Flag not found"
            )
        case .unknownError:
            return NSLocalizedString(
                "An unknown error occurred, couldn't read feature flag.",
                comment: "Unknown error."
            )
        case .incorrectType(let errorMessage):
            return NSLocalizedString(errorMessage, comment: "Flag type is incorrect")
        }
    }
}
