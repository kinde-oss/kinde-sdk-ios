# KindeSDK

[![Version](https://img.shields.io/cocoapods/v/KindeSDK.svg?style=flat)](https://cocoapods.org/pods/KindeSDK)
[![License](https://img.shields.io/cocoapods/l/KindeSDK.svg?style=flat)](https://cocoapods.org/pods/KindeSDK)
[![Platform](https://img.shields.io/cocoapods/p/KindeSDK.svg?style=flat)](https://cocoapods.org/pods/KindeSDK)

Integrate Kinde authentication with your iOS app. Simply **configure**, **register**, **login**, and **logout**, and authentication state is securely stored on the iOS keychain across app restarts.

You can also view the [iOS starter kit here](https://github.com/kinde-starter-kits/ios-starter-kit).

## Requirements

- iOS 13+
- Xcode 12+
- Swift 5+

## Installation

### Cocoapods

KindeSDK is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'KindeSDK'
```

Please note that `KindeSDK` is typically used with Cocoapods dynamic linking (`use_frameworks!`), as it takes a dependency on `AppAuth`.
If integrating with other pods that require static linking, follow the instructions provided by Cocoapods.

### Swift Package Manager

With [Swift Package Manager](https://swift.org/package-manager), 
add the following `dependency` to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/kinde-oss/kinde-sdk-ios.git", from: "1.1")
]
```

## Configuration

The Kinde `Auth` service is configured with an instance of the `Config` class. The example project uses the bundled `kinde-auth.json` for configuration.
Alternatively, configuration can be supplied in JSON format with the bundled `KindeAuth.plist`.
Enter the values from the [App Keys](https://kinde.com/docs/the-basics/getting-app-keys) page for your Kinde business: E.g.,

```
{
  "issuer": "https://{your-business}.kinde.com",
  "clientId": "{your-client-id}",
  "redirectUri": "{your-url-scheme}://kinde_callback",
  "postLogoutRedirectUri": "{your-url-scheme}://kinde_logoutcallback",
  "scope": "openid profile email offline",
}
```

Note: `your_url_scheme` can be any valid custom URL scheme, such as your app's bundle ID or an abbreviation.
It must match the scheme component of the _Allowed callback URLs_ and _Allowed logout redirect URLs_
you configure in your [App Keys](https://kinde.com/docs/the-basics/getting-app-keys) page for your Kinde business: E.g.,

```
{
  "issuer": "https://app.example.com",
  "clientId": "203185d2502246e1a7cb430fbeacc121",
  "redirectUri": "com.example.App://kinde_callback",
  "postLogoutRedirectUri": "com.example.App://kinde_logoutcallback",
  "scope": "openid profile email offline"
}
```

## Integrate with your app
Before `Auth` or any Kinde Management APIs can be used, a call to `KindeSDKAPI.configure()` must be made, typically in `AppDelegate`
as part of `application(launchOptions)` for a UIKit app, or the `@main` initialization logic for a SwiftUI app.

## Login / Register
The Kinde client provides methods for a simple login / register flow. Add buttons to your Storyboard/xib file and handle clicks as follows:

````
    ...
    @IBAction func signIn(_ sender: Any) {
      KindeSDKAPI.auth.login {}
    }
    
    @IBAction func signUp(_ sender: Any) {
      KindeSDKAPI.auth.register {}
    }
    ...
````

## Logout
This is implemented in much the same way as logging in or registering. The Kinde SDK client comes with a logout method.
````
    ....
    @IBAction func signOut(_ sender: Any) {
      KindeSDKAPI.auth.logout {}
    }
    ....
````


## Get user information
To access the user information, call the method `getUser`

````
    ...
    do {
        let userProfile = try await OAuthAPI.getUser()
        let userName = "\(userProfile.givenName ?? "") \(userProfile.familyName ?? "")"
        self.logger?.info(message: "Got profile for user \(userName)")
    } catch {}
    ...
````

## User Permissions
Once a user has been verified, your application will be returned the JWT token with an array of permissions for that user. You will need to configure your application to read permissions and unlock the respective functions.

[Set roles and permissions](https://kinde.com/docs/user-management/apply-roles-and-permissions-to-users/) at the Business level in Kinde. Here’s an example of permissions.
````
    let permissions = [
        “create:todos”,
        “update:todos”,
        “read:todos”,
        “delete:todos”,
        “create:tasks”,
        “update:tasks”,
        “read:tasks”,
        “delete:tasks”,
    ]
````

## Audience

An `audience` is the intended recipient of an access token.

When the request is received, Kinde will check that an API with a matching audience has been registered and is enabled for the application with the requested clientId. If there is a match it will return the `aud` claim as part of the access token.

When you use this access token in your product and send it to your product’s API, you can check for the audience in the token as part of your verification checks. You can find an audience on the details page of the API:

> Your profile on [Kinde.com](http://kinde.com/) -> Settings -> APIs -> View details of your API
> 

Please, make sure that you have enabled app and [registered an API](https://kinde.com/docs/build/register-an-api/) when using `audience`, you can do this here:

> Your profile on [Kinde.com](http://kinde.com/) -> Settings -> APIs -> View details of your API -> Applications (Side Panel) -> Your app (Front-end app by default) Switch enabled
> 

The `audience` argument must be an URL and can be passed to the `kinde-auth.json` or `KindeAuth.plist` configuration files.

Configuration example:

```swift
...
{
    “issuer”: “https://app.kinde.com”,
     “clientId”: “client_id”,
     “redirectUri”:“com.kinde.app://kinde_callback”,
     “postLogoutRedirectUri”: “com.kinde.app://kinde_logoutcallback”,
     “scope”: “openid profile email offline”,
     “audience”: “https://app.kinde.com/api”
}
...
```

## Getting claims
We have provided a helper to grab any claim from your id or access tokens. The helper defaults to access tokens:
````
    ...
    KindeSDKAPI.auth.getClaim(key: "aud")
    // "api.yourapp.com"
    KindeSDKAPI.auth.getClaim(key: "given_name", token: TokenType.idToken)
    // "David"
    ...
````

## Organizations Control
### Create an organization
To have a new organization created within your application, you will need to add buttons to your Storyboard/xib file and handle clicks as follows:

````
    ...
    @IBAction func createOrg(_ sender: Any) {
        KindeSDKAPI.auth.createOrg { }
    }
    ...
````
### Sign up and sign in to organizations
Kinde has a unique code for every organization. You’ll have to pass this code through when you register a new user. Example function below:

````
    ...
    @IBAction func signUp(_ sender: Any) {
      KindeSDKAPI.auth.register(orgCode: "your_org_code") {}
    }
    ...
````
If you want a user to sign into a particular organization, pass this code along with the sign in method:

````
    ...   
    @IBAction func signIn(_ sender: Any) {
        KindeSDKAPI.auth.login(orgCode: "your_org_code") {}
    }
    ...
````
Following authentication, Kinde provides a json web token (jwt) to your application. 
Along with the standard information we also include the `org_code` and the `permissions` for that organization (this is important as a user can belong to multiple organizations and have different permissions for each).

Example of a returned token:
````
    {
        "aud": [],
        "exp": 1658475930,
        "iat": 1658472329,
        "iss": "https://your_subdomain.kinde.com",
        "jti": "123457890",
        "org_code": "org_1234",
        "permissions": ["read:todos", "create:todos"],
        "scp": ["openid", "profile", "email", "offline"],
        "sub": "kp:123457890"
    }
````
The id_token will also contain an array of organizations that a user belongs to - this is useful if you wanted to build out an organization switcher for example.
````
    {
        ...
        "org_codes": ["org_1234", "org_4567"]
        ...
    }
````
There are two helper functions you can use to extract information:
````
    ...
    KindeSDKAPI.auth.getOrganization()
    // KindeSDK.Organization(code: "org_1234")
    KindeSDKAPI.auth.getUserOrganizations()
    // KindeSDK.UserOrganizations(orgCodes: [KindeSDK.Organization(code: "org_1234), KindeSDK.Organization(code: "org_abcd)])
    ...
````

## Kinde Management API

KindeSDK includes a client for the [Kinde Management API](./KindeSDK/Classes/KindeManagementAPI/README.md).
This client is generated by the [OpenApi Genenerator](https://openapi-generator.tech/docs/generators/swift5/).

Support for bearer token authentication is implemented by classes with the naming convention `Bearer`\*, according to the OpenAPI Generator [recommendation](https://github.com/OpenAPITools/openapi-generator/wiki/FAQ#how-do-i-implement-bearer-token-authentication-with-urlsession-on-the-swift-api-client).

Functions/methods targeting the Management API can only be accessed with tokens generated by the Client Credentials Auth flow at the moment. Since this SDK does not support the Client Credential flow, Management API functions are not available for use. In the future, tokens obtained via other flows would also be able to access the management API functions/methods.

## Development

Observe [Swift conventions](https://www.swift.org/documentation/api-design-guidelines/) where possible.

## Author

Kinde, kinde.com

## License

KindeSDK is available under the MIT license. See the LICENSE file for more info.
