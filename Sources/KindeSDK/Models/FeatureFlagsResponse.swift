import Foundation

/// Response from the feature flags API endpoint
public struct FeatureFlagsResponse: Codable {
    /// The data wrapper containing feature flags
    public let data: FeatureFlagsData?
    /// Whether the API call was successful
    public let success: Bool
    
    private enum CodingKeys: String, CodingKey {
        case data, success
    }
    
    /// Check if the response is valid
    public func isValid() -> Bool {
        return success && data != nil
    }
    
    /// Convert the API response to a map of flag keys to Flag objects
    /// - Returns: Map of flag keys to Flag objects. Invalid flags (null key/value or unknown type) are skipped.
    /// Valid types: "Boolean", "String", "Integer" (case-sensitive)
    public func toFlagMap() -> [String: Flag] {
        guard success else {
            return [:]
        }
        let flags = data?.featureFlags ?? []
        var flagMap: [String: Flag] = [:]
        
        for item in flags {
            guard let key = item.key else {
                continue
            }
            guard let value = item.value else {
                continue
            }
            
            let flagType: Flag.ValueType?
            switch item.type {
            case "Boolean":
                flagType = .bool
            case "String":
                flagType = .string
            case "Integer":
                flagType = .int
            default:
                continue
            }
            
            flagMap[key] = Flag(code: key, type: flagType, value: value.value, isDefault: false)
        }
        
        return flagMap
    }
}

