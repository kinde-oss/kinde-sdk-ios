import Foundation

/// Entitlements data container
public struct Entitlements: Codable {
    /// Organization code
    public let orgCode: String
    /// List of entitlement plans
    public let plans: [EntitlementPlan]
    /// List of entitlements
    public let entitlements: [Entitlement]
    
    private enum CodingKeys: String, CodingKey {
        case orgCode = "org_code"
        case plans, entitlements
    }
}
