import Foundation

/// Configuration options for API calls
/// - Parameter forceApi: When true, forces the SDK to fetch data from the API instead of token claims
public struct ApiOptions {
    /// When true, forces the SDK to fetch data from the API instead of token claims
    public let forceApi: Bool
    
    public init(forceApi: Bool = false) {
        self.forceApi = forceApi
    }
}
