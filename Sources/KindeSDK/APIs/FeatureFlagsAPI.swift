//
// FeatureFlagsAPI.swift
//
// API interface for fetching feature flags
//

import Foundation

/// API client for fetching feature flags from Kinde
final public class FeatureFlagsAPI {
    
    /**
     Get all feature flags for the authenticated user
     - GET /account_api/v1/feature_flags
     - Returns feature flags with their values
     - BASIC:
       - type: http
       - name: kindeBearerAuth
     - returns: FeatureFlagsResponse
     */
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    final public class func getFeatureFlags() async throws -> FeatureFlagsResponse {
        return try await getFeatureFlagsWithRequestBuilder().execute().body
    }
    
    /**
     Get all feature flags for the authenticated user
     - GET /account_api/v1/feature_flags
     - returns: RequestBuilder<FeatureFlagsResponse>
     */
    final public class func getFeatureFlagsWithRequestBuilder() -> RequestBuilder<FeatureFlagsResponse> {
        let localVariablePath = "/account_api/v1/feature_flags"
        let localVariableURLString = KindeSDKAPI.basePath + localVariablePath
        let localVariableParameters: [String: Any]? = nil
        
        let localVariableUrlComponents = URLComponents(string: localVariableURLString)
        
        let localVariableNillableHeaders: [String: Any?] = [:]
        
        let localVariableHeaderParameters = APIHelper.rejectNilHeaders(localVariableNillableHeaders)
        
        let localVariableRequestBuilder: RequestBuilder<FeatureFlagsResponse>.Type = KindeSDKAPI.requestBuilderFactory.getBuilder()
        
        return localVariableRequestBuilder.init(method: "GET", URLString: (localVariableUrlComponents?.string ?? localVariableURLString), parameters: localVariableParameters, headers: localVariableHeaderParameters, requiresAuthentication: true)
    }
}

