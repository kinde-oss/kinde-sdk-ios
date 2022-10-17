class BearerDecodableRequestBuilder<T: Decodable>: URLSessionDecodableRequestBuilder<T> {    
    @discardableResult
    override func execute(_ apiResponseQueue: DispatchQueue = OpenAPIClientAPI.apiResponseQueue, _ completion: @escaping (Result<Response<T>, ErrorResponse>) -> Void) -> RequestTask {
        
        BearerTokenHandler.setBearerToken { error in

            if let error = error {
                BearerTokenHandler.handleSetBearerTokenError(error: error, completion: completion)
            } else {
                super.execute(apiResponseQueue) { result in
                    completion(result)
                }
            }
        }
        
        return requestTask
    }
}
