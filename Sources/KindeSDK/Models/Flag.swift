import Foundation

/// Represents a feature flag with its code, type, and value
public struct Flag {
    public let code: String
    public let type: ValueType?
    public let value: Any
    public let isDefault: Bool

    public init(code: String, type: ValueType?, value: Any, isDefault: Bool = false) {
        self.code = code
        self.type = type
        self.value = value
        self.isDefault = isDefault
    }
    
    public enum ValueType: String {
        case string = "s"
        case int = "i"
        case bool = "b"
        
        var typeDescription: String {
            switch self {
            case .string: return "string"
            case .bool: return "boolean"
            case .int: return "integer"
            }
        }
    }
}
