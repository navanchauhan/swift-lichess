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
        // DocC plugin for documentation generation
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
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
            name: "PuzzlesRacerExample",
            dependencies: ["LichessClient"],
            path: "Examples/PuzzlesRacerExample"
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
            name: "StudiesExample",
            dependencies: ["LichessClient"],
            path: "Examples/StudiesExample"
        ),
        .executableTarget(
            name: "AdminExample",
            dependencies: ["LichessClient"],
            path: "Examples/AdminExample"
        ),
        .executableTarget(
            name: "OAuthExample",
            dependencies: ["LichessClient"],
            path: "Examples/OAuthExample"
        ),
        .executableTarget(
            name: "AutocompleteExample",
            dependencies: ["LichessClient"],
            path: "Examples/AutocompleteExample"
        ),
        .executableTarget(
            name: "OpeningExplorerExample",
            dependencies: ["LichessClient"],
            path: "Examples/OpeningExplorerExample"
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
            name: "UsersExample",
            dependencies: ["LichessClient"],
            path: "Examples/UsersExample"
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
        .executableTarget(
            name: "ArenaTournamentsExample",
            dependencies: ["LichessClient"],
            path: "Examples/ArenaTournamentsExample"
        ),
        .executableTarget(
            name: "SwissExample",
            dependencies: ["LichessClient"],
            path: "Examples/SwissExample"
        ),
        .testTarget(
            name: "LichessClientTests",
            dependencies: ["LichessClient"]),
    ]
)
