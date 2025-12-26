import Foundation

/// Represents a JWT claim with its name and value
public struct Claim: Codable {
    /// The name/key of the claim
    public let name: String
    
    /// The value of the claim (can be any type)
    public let value: AnyCodable
    
    public init(name: String, value: AnyCodable) {
        self.name = name
        self.value = value
    }
}
