import Foundation

/// Pagination metadata for API responses
public struct EntitlementsMetadata: Codable {
    /// Whether there are more pages available
    public let hasMore: Bool
    /// Token to get the next page of results
    public let nextPageStartingAfter: String?
    
    private enum CodingKeys: String, CodingKey {
        case hasMore = "has_more"
        case nextPageStartingAfter = "next_page_starting_after"
    }
}
