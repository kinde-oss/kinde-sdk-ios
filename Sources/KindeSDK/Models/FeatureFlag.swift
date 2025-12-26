import Foundation

/// Represents a feature flag with its value and metadata
public struct FeatureFlag: Codable {
    /// The feature flag code/identifier
    public let code: String
    
    /// The type of the feature flag value
    public let type: ValueType?
    
    /// The actual value of the feature flag
    public let value: AnyCodable
    
    /// Whether this is a default value
    public let isDefault: Bool
    
    public init(code: String, type: ValueType?, value: AnyCodable, isDefault: Bool = false) {
        self.code = code
        self.type = type
        self.value = value
        self.isDefault = isDefault
    }
    
    /// Enum representing the type of feature flag value
    public enum ValueType: String, Codable {
        case string = "s"
        case int = "i"
        case bool = "b"
        
        public var typeDescription: String {
            switch self {
            case .string: return "string"
            case .bool: return "boolean"
            case .int: return "integer"
            }
        }
    }
}
