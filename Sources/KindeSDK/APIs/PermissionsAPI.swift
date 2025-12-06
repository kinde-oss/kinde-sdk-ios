//
// PermissionsAPI.swift
//
// API interface for fetching user permissions
//

import Foundation

/// API client for fetching user permissions from Kinde
final public class PermissionsAPI {
    
    /**
     Get all permissions for the authenticated user
     - GET /account_api/v1/permissions
     - Returns permissions with org code and list of permission keys
     - BASIC:
       - type: http
       - name: kindeBearerAuth
     - returns: PermissionsResponse
     */
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    final public class func getPermissions() async throws -> PermissionsResponse {
        return try await getPermissionsWithRequestBuilder().execute().body
    }
    
    /**
     Get all permissions for the authenticated user
     - GET /account_api/v1/permissions
     - returns: RequestBuilder<PermissionsResponse>
     */
    final public class func getPermissionsWithRequestBuilder() -> RequestBuilder<PermissionsResponse> {
        let localVariablePath = "/account_api/v1/permissions"
        let localVariableURLString = KindeSDKAPI.basePath + localVariablePath
        let localVariableParameters: [String: Any]? = nil
        
        let localVariableUrlComponents = URLComponents(string: localVariableURLString)
        
        let localVariableNillableHeaders: [String: Any?] = [:]
        
        let localVariableHeaderParameters = APIHelper.rejectNilHeaders(localVariableNillableHeaders)
        
        let localVariableRequestBuilder: RequestBuilder<PermissionsResponse>.Type = KindeSDKAPI.requestBuilderFactory.getBuilder()
        
        return localVariableRequestBuilder.init(method: "GET", URLString: (localVariableUrlComponents?.string ?? localVariableURLString), parameters: localVariableParameters, headers: localVariableHeaderParameters, requiresAuthentication: true)
    }
}

