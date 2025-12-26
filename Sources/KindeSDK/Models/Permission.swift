import Foundation

/// Represents a permission with organization context
public struct Permission: Codable {
    /// The organization this permission belongs to
    public let organization: Organization
    
    /// Whether the permission is granted
    public let isGranted: Bool
    
    public init(organization: Organization, isGranted: Bool) {
        self.organization = organization
        self.isGranted = isGranted
    }
}

/// Collection of permissions
public struct Permissions: Codable {
    /// The organization these permissions belong to
    public let organization: Organization
    
    /// List of permission names
    public let permissions: [String]
    
    public init(organization: Organization, permissions: [String]) {
        self.organization = organization
        self.permissions = permissions
    }
}
