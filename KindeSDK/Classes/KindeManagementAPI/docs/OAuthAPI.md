# OAuthAPI

All URIs are relative to *https://app.kinde.com*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getUser**](OAuthAPI.md#getuser) | **GET** /oauth2/v2/user_profile | Returns the details of the currently logged in user


# **getUser**
```swift
    open class func getUser(completion: @escaping (_ data: UserProfile?, _ error: Error?) -> Void)
```

Returns the details of the currently logged in user

Contains the id, names and email of the currently logged in user 

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient


// Returns the details of the currently logged in user
OAuthAPI.getUser() { (response, error) in
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
This endpoint does not need any parameter.

### Return type

[**UserProfile**](UserProfile.md)

### Authorization

[kindeBearerAuth](../README.md#kindeBearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

