class BearerDecodableRequestBuilder<T: Decodable>: URLSessionDecodableRequestBuilder<T> {    
    @discardableResult
    override func execute(_ apiResponseQueue: DispatchQueue = OpenAPIClientAPI.apiResponseQueue, _ completion: @escaping (Result<Response<T>, ErrorResponse>) -> Void) -> RequestTask {
        
        BearerTokenHandler.setBearerToken { error in

            if let error = error {
                switch error {
                case AuthError.notAuthenticated:
                    // Indicate a bearer token could not be set due to an authentication error; likely due to an expired refresh token
                    completion(Result.failure(ErrorResponse.error(BearerTokenHandler.notAuthenticatedCode, nil, nil, error)))
                default:
                    completion(Result.failure(ErrorResponse.error(-1, nil, nil, error)))
                }
                
            } else {
                super.execute(apiResponseQueue) { result in
                    completion(result)
                }
            }
        }
        
        return requestTask
    }
}
