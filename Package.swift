// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "swift-lichess",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .visionOS(.v1)],
    products: [
        .library(
            name: "LichessClient",
            targets: ["LichessClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "LichessClient",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
            ], swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "PuzzlesExample",
            dependencies: ["LichessClient"],
            path: "Examples/PuzzlesExample"
        ),
        .executableTarget(
            name: "TVStreamExample",
            dependencies: ["LichessClient"],
            path: "Examples/TVStreamExample"
        ),
        .executableTarget(
            name: "TVChannelsExample",
            dependencies: ["LichessClient"],
            path: "Examples/TVChannelsExample"
        ),
        .executableTarget(
            name: "PlayersExample",
            dependencies: ["LichessClient"],
            path: "Examples/PlayersExample"
        ),
        .executableTarget(
            name: "CloudEvalExample",
            dependencies: ["LichessClient"],
            path: "Examples/CloudEvalExample"
        ),
        .executableTarget(
            name: "CrosstableExample",
            dependencies: ["LichessClient"],
            path: "Examples/CrosstableExample"
        ),
        .executableTarget(
            name: "SimulsExample",
            dependencies: ["LichessClient"],
            path: "Examples/SimulsExample"
        ),
        .executableTarget(
            name: "StreamersExample",
            dependencies: ["LichessClient"],
            path: "Examples/StreamersExample"
        ),
        .executableTarget(
            name: "TeamsExample",
            dependencies: ["LichessClient"],
            path: "Examples/TeamsExample"
        ),
        .executableTarget(
            name: "BulkPairingExample",
            dependencies: ["LichessClient"],
            path: "Examples/BulkPairingExample"
        ),
        .executableTarget(
            name: "ExternalEngineExample",
            dependencies: ["LichessClient"],
            path: "Examples/ExternalEngineExample"
        ),
        .executableTarget(
            name: "BoardExample",
            dependencies: ["LichessClient"],
            path: "Examples/BoardExample"
        ),
        .executableTarget(
            name: "BotExample",
            dependencies: ["LichessClient"],
            path: "Examples/BotExample"
        ),
        .executableTarget(
            name: "ChallengesExample",
            dependencies: ["LichessClient"],
            path: "Examples/ChallengesExample"
        ),
        .executableTarget(
            name: "BroadcastsExample",
            dependencies: ["LichessClient"],
            path: "Examples/BroadcastsExample"
        ),
        .executableTarget(
            name: "GameExportExample",
            dependencies: ["LichessClient"],
            path: "Examples/GameExportExample"
        ),
        .executableTarget(
            name: "AccountExample",
            dependencies: ["LichessClient"],
            path: "Examples/AccountExample"
        ),
        .testTarget(
            name: "LichessClientTests",
            dependencies: ["LichessClient"]),
    ]
)
