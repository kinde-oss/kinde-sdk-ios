import Foundation

/// Entitlements API response with pagination
public struct EntitlementsResponse: Codable {
    /// The entitlements data
    public let data: Entitlements
    /// Pagination metadata
    public let metadata: EntitlementsMetadata
}

/// Single entitlement response
public struct EntitlementResponse: Codable {
    /// The entitlement data
    public let data: Entitlement
}
