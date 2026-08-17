// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if os(Linux) || os(Android)
let dependencies: [Pacakge.Dependency] = [
    .package(url: "https://github.com/apple/swift-crypto.git", from: .init(4, 5, 0))
]
#else
let dependencies: [Package.Dependency] = []
#endif

let package = Package(
    name: "OAuthKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v15),
        .tvOS(.v18),
        .visionOS(.v1),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "OAuthKit",
            targets: ["OAuthKit"])
    ],
    dependencies: dependencies,
    targets: [
        .target(
            name: "OAuthKit",
            linkerSettings: [
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
        ),
        .testTarget(
            name: "OAuthKitTests",
            dependencies: ["OAuthKit"],
            resources: [.process("Resources")]
        )
    ]
)
