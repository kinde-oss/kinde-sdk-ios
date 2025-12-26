import Foundation

/// Entitlement plan model
public struct EntitlementPlan: Codable {
    /// The plan code
    public let code: String
    /// The plan name
    public let name: String?
    /// The plan description
    public let description: String?
}
