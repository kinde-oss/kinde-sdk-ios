class BearerRequestBuilderFactory: RequestBuilderFactory {
    
    func getNonDecodableBuilder<T>() -> RequestBuilder<T>.Type {
        BearerRequestBuilder<T>.self
    }

    func getBuilder<T: Decodable>() -> RequestBuilder<T>.Type {
        BearerDecodableRequestBuilder<T>.self
    }
}
