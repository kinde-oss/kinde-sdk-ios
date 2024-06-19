// swift-tools-version:5.1

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
	    .package(url: "https://github.com/openid/AppAuth-iOS.git", from: "1.6.2")
    ],
    targets: [
        .target(
            name: "KindeSDK",
            dependencies: [
		        .product(name: "AppAuth", package: "AppAuth-iOS")
		 ],
            path: "Sources/KindeSDK/"
        )
    ],
    swiftLanguageVersions: [.v5]
)
