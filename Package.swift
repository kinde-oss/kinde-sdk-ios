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
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "KindeSDK",
            targets: ["KindeSDK"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "KindeSDK",
            dependencies: []),
    ],
    swiftLanguageVersions: [.v5]
)
