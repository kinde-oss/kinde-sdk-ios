# KindeAuthSwift

[![Version](https://img.shields.io/cocoapods/v/KindeAuthSwift.svg?style=flat)](https://cocoapods.org/pods/KindeAuthSwift)
[![License](https://img.shields.io/cocoapods/l/KindeAuthSwift.svg?style=flat)](https://cocoapods.org/pods/KindeAuthSwift)
[![Platform](https://img.shields.io/cocoapods/p/KindeAuthSwift.svg?style=flat)](https://cocoapods.org/pods/KindeAuthSwift)

Integrate Kinde authentication with your iOS app. **register**, **login**, **logout**, and securely store authentication state on the iOS keychain.

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

- iOS 12.4+
- Xcode 12+
- Swift 5+

## Installation

KindeAuthSwift is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'KindeAuthSwift'
```

## Configuration

The Kinde `AuthService` is configured with an instance of the `Config` class. The example project uses the bundled `config.json` file for configuration. Enter the values for your [Kinde business](https://kinde.com/docs/the-basics/getting-app-keys): E.g.,

```
{
  "issuer": "https://{your-business}.kinde.com",
  "clientId": "{your-client-id}",
  "redirectUri": "{your-app-bundle-id}://callback",
  "postLogoutRedirectUri": "{your-app-bundle-id}://logoutcallback",
  "scope": "offline openid"
}
```

TODO: test. OpenUrl handler for older iOS?

## Author

Kinde, kinde.com

## License

KindeAuthSwift is available under the MIT license. See the LICENSE file for more info.
