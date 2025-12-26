import Foundation

/// Collection of user organizations
public struct UserOrganizations: Codable {
    /// List of organization codes
    public let orgCodes: [Organization]
    
    public init(orgCodes: [Organization]) {
        self.orgCodes = orgCodes
    }
}
