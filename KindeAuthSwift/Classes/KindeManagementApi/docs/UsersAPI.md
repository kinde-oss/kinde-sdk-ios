# UsersAPI

All URIs are relative to *https://app.kinde.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getUsers**](UsersAPI.md#getusers) | **GET** /users | Returns a paginated list of end-user records for a business


# **getUsers**
```swift
    open class func getUsers(sort: Sort_getUsers? = nil, pageSize: Int? = nil, userId: Int? = nil, nextToken: String? = nil, completion: @escaping (_ data: Users?, _ error: Error?) -> Void)
```

Returns a paginated list of end-user records for a business

The returned list can be sorted by full name or email address in ascending or descending order. The number of records to return at a time can also be controlled using the page_size query string parameter.  

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let sort = "sort_example" // String | Describes the field and order to sort the result by (optional)
let pageSize = 987 // Int | The number of items to return (optional)
let userId = 987 // Int | The id of the user to filter by (optional)
let nextToken = "nextToken_example" // String | A string to get the next page of results if there are more results (optional)

// Returns a paginated list of end-user records for a business
UsersAPI.getUsers(sort: sort, pageSize: pageSize, userId: userId, nextToken: nextToken) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **sort** | **String** | Describes the field and order to sort the result by | [optional] 
 **pageSize** | **Int** | The number of items to return | [optional] 
 **userId** | **Int** | The id of the user to filter by | [optional] 
 **nextToken** | **String** | A string to get the next page of results if there are more results | [optional] 

### Return type

[**Users**](Users.md)

### Authorization

[kindeBearerAuth](../README.md#kindeBearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

