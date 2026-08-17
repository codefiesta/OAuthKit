// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let supportedPlatforms: [SupportedPlatform] = [
    .iOS(.v17),
    .macOS(.v15),
    .tvOS(.v18),
    .visionOS(.v1),
    .watchOS(.v10)
]
var packageDependencies: [Package.Dependency] = []
var targetDependencies: [Target.Dependency] = []
var linkerSettings: [LinkerSetting] = []
let platforms: [Platform] = [.iOS, .macOS, .tvOS, .watchOS, .visionOS]

#if os(Linux) || os(Android)
// Android and Linux
packageDependencies = [
    .package(url: "https://github.com/apple/swift-crypto.git", from: .init(4, 5, 0))
]
targetDependencies = [
    .product(name: "Crypto", package: "swift-crypto")
]
#else
// Apple
linkerSettings = [
    .linkedFramework("CryptoKit",
        .when(platforms: platforms)
    ),
    .linkedFramework("LocalAuthentication",
        .when(platforms: platforms)
    ),
    .linkedFramework("Network",
        .when(platforms: platforms)
    ),
    .linkedFramework("Security",
        .when(platforms: platforms)
    ),
]
#endif

let package = Package(
    name: "OAuthKit",
    platforms: supportedPlatforms,
    products: [
        .library(
            name: "OAuthKit",
            targets: ["OAuthKit"])
    ],
    dependencies: packageDependencies,
    targets: [
        .target(
            name: "OAuthKit",
            dependencies: targetDependencies,
            linkerSettings: linkerSettings
        ),
        .testTarget(
            name: "OAuthKitTests",
            dependencies: ["OAuthKit"],
            resources: [.process("Resources")]
        )
    ]
)
