import AppAuth

public class BearerTokenHandler {
    static let notAuthenticatedCode = 401
    
    /// Ensure a valid Bearer token is present.
    ///
    /// Token refresh is performed using the `AppAuth` convenience function, `performWithFreshTokens`
    /// This will refresh an expired access token if required, and if the refresh token is expired,
    /// a fresh login will need to be performed.
    ///
    /// A failure with error `notAuthenticatedCode` likely indicates a fresh login is required.
    @available(*, renamed: "setBearerToken()")
    func setBearerToken(completionHandler: @escaping (Error?) -> Void) {
        Task {
            do {
                try await setBearerToken()
                completionHandler(nil)
            } catch {
                completionHandler(error)
            }
        }
    }
    
    
    func setBearerToken() async throws {
        do {
            if let tokens = try await Auth.performWithFreshTokens() {
                KindeSDKAPI.customHeaders["Authorization"] = "Bearer \(tokens.accessToken)"
            }
            return
        } catch let error {
            print("Failed to get auth token: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Transform an error arising from `setBearerToken` into an `ErrorResponse`
    ///
    /// Authentication errors are given response code `notAuthenticatedCode` and will likely require a fresh login. All other
    /// errors are given a nominal value.
    @available(*, renamed: "handleSetBearerTokenError(error:)")
    func handleSetBearerTokenError<T>(error: Error, completion: @escaping (Result<Response<T>, ErrorResponse>) -> Void) {
        Task {
            do {
                let result: Response<T> = try await handleSetBearerTokenError(error: error)
                completion(.success(result))
            } catch {
                completion(.failure(error as! ErrorResponse))
            }
        }
    }
    
    
    func handleSetBearerTokenError<T>(error: Error) async throws -> Response<T> {
        switch error {
        case AuthError.notAuthenticated:
            // Indicate a bearer token could not be set due to an authentication error; likely due to an expired refresh token
            throw ErrorResponse.error(BearerTokenHandler.notAuthenticatedCode, nil, nil, error)
        default:
            throw ErrorResponse.error(-1, nil, nil, error)
        }
    }
}
