public class KindeManagementApiClient {
    public static func getUsers(sort: UsersAPI.Sort_getUsers? = nil, pageSize: Int? = nil, userId: Int? = nil, nextToken: String? = nil, then completion: @escaping ((_ data: Users?, _ error: Error?) -> Void)) {
        UsersAPI.getUsers(sort: sort, pageSize: pageSize, userId: userId, nextToken: nextToken, completion: completion)
    }
    
    public static func getUser(then completion: @escaping ((_ data: UserProfile?, _ error: Error?) -> Void)) {
        OAuthAPI.getUser(completion: completion)
    }
}
