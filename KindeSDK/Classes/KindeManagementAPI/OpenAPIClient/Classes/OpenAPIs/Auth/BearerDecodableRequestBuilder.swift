class BearerDecodableRequestBuilder<T: Decodable>: URLSessionDecodableRequestBuilder<T> {    
    @discardableResult
    override func execute(_ apiResponseQueue: DispatchQueue = OpenAPIClientAPI.apiResponseQueue, _ completion: @escaping (Result<Response<T>, ErrorResponse>) -> Void) async -> RequestTask {
        let bearerTokenHandler = BearerTokenHandler()
        do {
            try await bearerTokenHandler.setBearerToken()
            super.execute(apiResponseQueue) { result in
                completion(result)
            }
        } catch let error {
            do {
                let result: Response<T> = try await bearerTokenHandler.handleSetBearerTokenError(error: error)
                completion(.success(result))
            } catch {
                completion(.failure(error as! ErrorResponse))
            }
        }
        
        return requestTask
    }
}