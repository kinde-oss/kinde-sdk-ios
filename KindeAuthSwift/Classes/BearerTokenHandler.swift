import AppAuth

public class BearerTokenHandler {
    public static let notAuthenticatedCode = 401
    
    /// Ensure a valid Bearer token is present.
    ///
    /// Token refresh is performed using the `AppAuth` convenience function, `performWithFreshTokens`
    /// This will refresh an expired access token if required, and if the refresh token is expired,
    /// a fresh login will need to be performed.
    ///
    /// A failure with error `notAuthenticatedCode` likely indicates a fresh login is required.
    static func setBearerToken(completionHandler: @escaping (Error?) -> Void) {
        Auth.performWithFreshTokens { tokens in
            switch tokens {
            case let .failure(error):
                print("Failed to get auth token: \(error.localizedDescription)")
                completionHandler(error)
            case let .success(tokens):
                OpenAPIClientAPI.customHeaders["Authorization"] = "Bearer \(tokens.accessToken)"
                completionHandler(nil)
            }
        }
    }
}
