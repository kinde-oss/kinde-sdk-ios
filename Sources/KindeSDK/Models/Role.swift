import Foundation

/// Represents a role with organization context
public struct Role: Codable {
    /// The organization this role belongs to
    public let organization: Organization
    
    /// Whether the role is granted
    public let isGranted: Bool
    
    public init(organization: Organization, isGranted: Bool) {
        self.organization = organization
        self.isGranted = isGranted
    }
}

/// Collection of roles
public struct Roles: Codable {
    /// The organization these roles belong to
    public let organization: Organization
    
    /// List of role names
    public let roles: [String]
    
    public init(organization: Organization, roles: [String]) {
        self.organization = organization
        self.roles = roles
    }
}
