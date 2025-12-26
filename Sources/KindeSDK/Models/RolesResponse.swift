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

