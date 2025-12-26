import Foundation

/// Response from the permissions API endpoint
public struct PermissionsResponse: Codable {
    /// The data wrapper containing permissions
    public let data: PermissionsData?
    /// Whether the API call was successful
    public let success: Bool
    
    private enum CodingKeys: String, CodingKey {
        case data, success
    }
    
    /// Check if the response is valid
    public func isValid() -> Bool {
        return success && data != nil
    }
    
    /// Extract permission keys from the API response
    /// - Returns: List of permission keys. Permissions with null keys are skipped.
    public func getPermissionKeys() -> [String] {
        guard success else {
            return []
        }
        let permissions = data?.permissions ?? []
        return permissions.compactMap { $0.key }
    }
}

