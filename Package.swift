// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OAuthKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "OAuthKit",
            targets: ["OAuthKit"])
    ],
    targets: [
        .target(
            name: "OAuthKit",
            linkerSettings: [
                .linkedFramework("CryptoKit"),
                .linkedFramework("LocalAuthentication", .when(
                    platforms: [.iOS]
                )),
                .linkedFramework("Network"),
                .linkedFramework("Security")
            ]
        ),
        .testTarget(
            name: "OAuthKitTests",
            dependencies: ["OAuthKit"],
            resources: [.process("Resources/")]
        )
    ]
)
