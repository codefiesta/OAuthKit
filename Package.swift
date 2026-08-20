// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

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
    dependencies: [
        // Android / Linux Dependencies
        .package(url: "https://github.com/apple/swift-crypto", from: .init(4, 5, 0))
    ],
    targets: [
        .target(
            name: "OAuthKit",
            dependencies: [
                .product(name: "Crypto",
                         package: "swift-crypto",
                         condition: .when(platforms: [.android, .linux])
                )
            ],
            linkerSettings: [
                .linkedFramework("LocalAuthentication",
                    .when(platforms: [.iOS])
                ),
            ]
        ),
        .testTarget(
            name: "OAuthKitTests",
            dependencies: ["OAuthKit"],
            resources: [.process("Resources")]
        )
    ]
)
