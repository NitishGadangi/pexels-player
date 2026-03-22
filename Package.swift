// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PexelsPlayer",
    platforms: [.iOS(.v16)],
    products: [
        // Libraries
        .library(name: "NetworkLib", targets: ["NetworkLib"]),
        .library(name: "CacheLib", targets: ["CacheLib"]),
        .library(name: "UIComponents", targets: ["UIComponents"]),
        .library(name: "LoggingLib", targets: ["LoggingLib"]),

        // Shared Models
        .library(name: "SharedModelsInterface", targets: ["SharedModelsInterface"]),

        // SharedRouter
        .library(name: "SharedRouterInterface", targets: ["SharedRouterInterface"]),
        .library(name: "SharedRouter", targets: ["SharedRouter"]),

        // Home
        .library(name: "HomeInterface", targets: ["HomeInterface"]),
        .library(name: "Home", targets: ["Home"]),

        // VideoFeed
        .library(name: "VideoFeedInterface", targets: ["VideoFeedInterface"]),
        .library(name: "VideoFeed", targets: ["VideoFeed"]),

        // SavedItems
        .library(name: "SavedItemsInterface", targets: ["SavedItemsInterface"]),
        .library(name: "SavedItems", targets: ["SavedItems"]),
    ],
    targets: [
        // MARK: - Libraries

        .target(
            name: "NetworkLib",
            path: "Modules/Libraries/NetworkLib/Sources"
        ),
        .target(
            name: "CacheLib",
            path: "Modules/Libraries/CacheLib/Sources"
        ),
        .target(
            name: "UIComponents",
            dependencies: ["CacheLib"],
            path: "Modules/Libraries/UIComponents/Sources"
        ),
        .target(
            name: "LoggingLib",
            path: "Modules/Libraries/LoggingLib/Sources"
        ),

        // MARK: - Shared Models

        .target(
            name: "SharedModelsInterface",
            path: "Modules/SharedModels/SharedModelsInterface/Sources"
        ),

        // MARK: - SharedRouter

        .target(
            name: "SharedRouterInterface",
            path: "Modules/SharedRouter/SharedRouterInterface/Sources"
        ),
        .target(
            name: "SharedRouter",
            dependencies: [
                "SharedRouterInterface",
                "HomeInterface",
                "VideoFeedInterface",
                "SavedItemsInterface",
            ],
            path: "Modules/SharedRouter/SharedRouter/Sources"
        ),

        // MARK: - Home

        .target(
            name: "HomeInterface",
            dependencies: ["SharedModelsInterface"],
            path: "Modules/Home/HomeInterface/Sources"
        ),
        .target(
            name: "Home",
            dependencies: [
                "HomeInterface",
                "SharedModelsInterface",
                "NetworkLib",
                "UIComponents",
                "LoggingLib",
                "SharedRouterInterface",
            ],
            path: "Modules/Home/Home/Sources"
        ),

        // MARK: - VideoFeed

        .target(
            name: "VideoFeedInterface",
            dependencies: ["SharedModelsInterface"],
            path: "Modules/VideoFeed/VideoFeedInterface/Sources"
        ),
        .target(
            name: "VideoFeed",
            dependencies: [
                "VideoFeedInterface",
                "SharedModelsInterface",
                "UIComponents",
                "LoggingLib",
                "SharedRouterInterface",
            ],
            path: "Modules/VideoFeed/VideoFeed/Sources"
        ),

        // MARK: - SavedItems

        .target(
            name: "SavedItemsInterface",
            path: "Modules/SavedItems/SavedItemsInterface/Sources"
        ),
        .target(
            name: "SavedItems",
            dependencies: [
                "SavedItemsInterface",
                "UIComponents",
                "SharedRouterInterface",
            ],
            path: "Modules/SavedItems/SavedItems/Sources"
        ),

        // MARK: - Tests

        .testTarget(
            name: "HomeTests",
            dependencies: ["Home", "HomeInterface", "SharedModelsInterface", "NetworkLib"],
            path: "PexelsPlayerTests/HomeTests"
        ),
        .testTarget(
            name: "VideoFeedTests",
            dependencies: ["VideoFeed", "VideoFeedInterface", "SharedModelsInterface"],
            path: "PexelsPlayerTests/VideoFeedTests"
        ),
    ]
)
