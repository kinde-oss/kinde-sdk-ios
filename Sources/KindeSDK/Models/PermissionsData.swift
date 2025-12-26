import Foundation

/// Data wrapper for permissions
public struct PermissionsData: Codable {
    /// Organization code
    public let orgCode: String?
    /// List of permissions
    public let permissions: [PermissionItem]
    
    private enum CodingKeys: String, CodingKey {
        case orgCode = "org_code"
        case permissions
    }
}

/// Individual permission item
public struct PermissionItem: Codable {
    /// Permission ID
    public let id: String?
    /// Permission key/name
    public let key: String?
    /// Permission display name
    public let name: String?
}
