import Foundation

class BearerDecodableRequestBuilder<T: Decodable>: URLSessionDecodableRequestBuilder<T> {
    private let bearerTokenHandler = BearerTokenHandler()
    
    @discardableResult
    override func execute(_ apiResponseQueue: DispatchQueue = KindeSDKAPI.apiResponseQueue, _ completion: @escaping (Result<Response<T>, ErrorResponse>) -> Void) -> RequestTask {
        guard requestTask.isCancelled == false else {
            completion(.failure(ErrorResponse.error(415, nil, nil, DecodableRequestBuilderError.unsuccessfulHTTPStatusCode)))
            return requestTask
        }
        
        bearerTokenHandler.setBearerToken { error in
            if let error = error {
                self.bearerTokenHandler.handleSetBearerTokenError(error: error, completion: completion)
            } else {
                super.execute(apiResponseQueue) { result in
                    completion(result)
                }
            }
        }        
        return requestTask
    }
}
