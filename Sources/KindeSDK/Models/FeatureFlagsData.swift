import Foundation

/// Data wrapper for feature flags
public struct FeatureFlagsData: Codable {
    /// List of feature flags
    public let featureFlags: [FeatureFlagItem]
    
    private enum CodingKeys: String, CodingKey {
        case featureFlags = "feature_flags"
    }
}

/// Individual feature flag item
public struct FeatureFlagItem: Codable {
    /// Feature flag ID
    public let id: String?
    /// Feature flag key/code
    public let key: String?
    /// Feature flag display name
    public let name: String?
    /// Feature flag type (Boolean, String, Integer)
    public let type: String?
    /// Feature flag value
    public let value: AnyCodable?
}
