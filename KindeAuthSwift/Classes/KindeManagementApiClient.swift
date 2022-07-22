/**
  A thin client for accessing the Kinde Management API.
 
  Note: an access token for the authorized user is set as a custom header in `OpenAPIClientAPI` before each call due to the Bearer security declaration in the API specification
  not being exposed as a parameter in the OpenAPI generatated requests (an apparent bug).
 */
public class KindeManagementApiClient {
    public static func getUsers(sort: UsersAPI.Sort_getUsers? = nil, pageSize: Int? = nil, userId: Int? = nil, nextToken: String? = nil, accessToken: String, then completion: @escaping ((_ data: Users?, _ error: Error?) -> Void)) {
        OpenAPIClientAPI.customHeaders = [ "Authorization": "Bearer \(accessToken)" ]
        
        UsersAPI.getUsers(sort: sort, pageSize: pageSize, userId: userId, nextToken: nextToken, completion: completion)
    }
    
    public static func getUser(accessToken: String, then completion: @escaping ((_ data: UserProfile?, _ error: Error?) -> Void)) {
        OpenAPIClientAPI.customHeaders = [ "Authorization": "Bearer \(accessToken)" ]
        
        OAuthAPI.getUser(completion: completion)
    }
}
