import Foundation

/// Data wrapper for roles
public struct RolesData: Codable {
    /// Organization code
    public let orgCode: String?
    /// List of roles
    public let roles: [RoleItem]
    
    private enum CodingKeys: String, CodingKey {
        case orgCode = "org_code"
        case roles
    }
}

/// Individual role item
public struct RoleItem: Codable {
    /// Role ID
    public let id: String?
    /// Role key/name
    public let key: String?
    /// Role display name
    public let name: String?
}
