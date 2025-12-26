import Foundation

/// Individual entitlement model
public struct Entitlement: Codable {
    /// The entitlement key/name
    public let key: String
    /// The entitlement value
    public let value: AnyCodable
    /// The entitlement type
    public let type: String?
    
    private enum CodingKeys: String, CodingKey {
        case key, value, type
    }
}
