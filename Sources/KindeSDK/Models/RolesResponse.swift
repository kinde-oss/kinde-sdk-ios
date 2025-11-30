import Foundation

/// Response from the roles API endpoint
public struct RolesResponse: Codable {
    /// The data wrapper containing roles
    public let data: RolesData?
    /// Whether the API call was successful
    public let success: Bool
    
    private enum CodingKeys: String, CodingKey {
        case data, success
    }
    
    /// Check if the response is valid
    public func isValid() -> Bool {
        return success && data != nil
    }
    
    /// Extract role keys from the API response
    /// - Returns: List of role keys. Roles with null keys are skipped.
    public func getRoleKeys() -> [String] {
        guard success else {
            return []
        }
        let roles = data?.roles ?? []
        return roles.compactMap { $0.key }
    }
}

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

