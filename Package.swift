// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var packageDependencies: [Package.Dependency] = []
var targetDependencies: [Target.Dependency] = []
var linkerSettings: [LinkerSetting] = []
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
        .when(platforms: [.iOS, .macOS, .tvOS, .visionOS, .watchOS])
    ),
    .linkedFramework("LocalAuthentication",
        .when(platforms: [.iOS])
    ),
    .linkedFramework("Network",
        .when(platforms: [.iOS, .macOS, .tvOS, .visionOS, .watchOS])
    ),
    .linkedFramework("Security",
        .when(platforms: [.iOS, .macOS, .tvOS, .visionOS, .watchOS])
    )
]
#endif

let package = Package(
    name: "OAuthKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v15),
        .tvOS(.v18),
        .visionOS(.v1),
        .watchOS(.v10),
    ],
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
