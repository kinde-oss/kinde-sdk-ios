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
        .package(url: "https://github.com/openid/AppAuth-iOS.git", .upToNextMajor(from: "1.3.0")),
        .package(url: "https://github.com/jrendel/SwiftKeychainWrapper.git", .upToNextMajor(from: "3.0.1"))        
    ],
    targets: [
        .target(
            name: "KindeSDK",
            dependencies: ["AppAuth-iOS", "SwiftKeychainWrapper"],
            path: "Sources/KindeSDK/Classes/KindeManagementAPI/OpenAPIClient/"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
