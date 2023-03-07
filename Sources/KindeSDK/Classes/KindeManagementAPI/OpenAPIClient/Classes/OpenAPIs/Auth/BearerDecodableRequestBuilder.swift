class BearerDecodableRequestBuilder<T: Decodable>: URLSessionDecodableRequestBuilder<T> {
    @discardableResult
    override func execute(_ apiResponseQueue: DispatchQueue = OpenAPIClientAPI.apiResponseQueue, _ completion: @escaping (Result<Response<T>, ErrorResponse>) -> Void) -> RequestTask {
        let bearerTokenHandler = BearerTokenHandler()
        bearerTokenHandler.setBearerToken { error in

            if let error = error {
                bearerTokenHandler.handleSetBearerTokenError(error: error, completion: completion)
            } else {
                super.execute(apiResponseQueue) { result in
                    completion(result)
                }
            }
        }
        
        return requestTask
    }
}
