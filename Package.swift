// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "KindeSDK",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_11),
        .tvOS(.v9),
        .watchOS(.v3),
    ],
    products: [
        .library(
            name: "KindeSDK",
            targets: ["KindeSDK"]
        ),
    ],
    dependencies: [
        .package(name: "AppAuth", url: "https://github.com/openid/AppAuth-iOS.git", from: "1.6.0"),
        .package(name: "SwiftKeychainWrapper", url: "https://github.com/jrendel/SwiftKeychainWrapper.git", from: "4.0.1"),
    ],
    targets: [
        .target(
            name: "KindeSDK",
            dependencies: ["AppAuth", "SwiftKeychainWrapper"],
            path: "Sources/KindeSDK/Classes/KindeManagementAPI/OpenAPIClient/"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
