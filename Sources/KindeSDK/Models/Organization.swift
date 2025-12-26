import Foundation

/// Represents an organization
public struct Organization: Codable {
    /// The organization code
    public let code: String
    
    public init(code: String) {
        self.code = code
    }
}
