//
// RolesAPI.swift
//
// API interface for fetching user roles
//

import Foundation

/// API client for fetching user roles from Kinde
final public class RolesAPI {
    
    /**
     Get all roles for the authenticated user
     - GET /account_api/v1/roles
     - Returns roles with org code and list of role keys
     - BASIC:
       - type: http
       - name: kindeBearerAuth
     - returns: RolesResponse
     */
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    final public class func getRoles() async throws -> RolesResponse {
        return try await getRolesWithRequestBuilder().execute().body
    }
    
    /**
     Get all roles for the authenticated user
     - GET /account_api/v1/roles
     - returns: RequestBuilder<RolesResponse>
     */
    final public class func getRolesWithRequestBuilder() -> RequestBuilder<RolesResponse> {
        let localVariablePath = "/account_api/v1/roles"
        let localVariableURLString = KindeSDKAPI.basePath + localVariablePath
        let localVariableParameters: [String: Any]? = nil
        
        let localVariableUrlComponents = URLComponents(string: localVariableURLString)
        
        let localVariableNillableHeaders: [String: Any?] = [:]
        
        let localVariableHeaderParameters = APIHelper.rejectNilHeaders(localVariableNillableHeaders)
        
        let localVariableRequestBuilder: RequestBuilder<RolesResponse>.Type = KindeSDKAPI.requestBuilderFactory.getBuilder()
        
        return localVariableRequestBuilder.init(method: "GET", URLString: (localVariableUrlComponents?.string ?? localVariableURLString), parameters: localVariableParameters, headers: localVariableHeaderParameters, requiresAuthentication: true)
    }
}

