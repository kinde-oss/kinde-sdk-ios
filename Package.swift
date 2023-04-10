// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "KindeSDK",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "KindeSDK",
            targets: ["KindeSDK"]
        ),
    ],
    dependencies: [
        .package(name: "AppAuth", url: "https://github.com/openid/AppAuth-iOS.git", from: "1.6.0")
    ],
    targets: [
        .target(
            name: "KindeSDK",
            dependencies: ["AppAuth"],
            path: "Sources/KindeSDK/"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
