// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "SendbirdUIComponents",
    platforms: [
        .macOS(.v12),
        .iOS(.v14),
        .tvOS(.v14),
        .watchOS(.v7),
        .macCatalyst(.v15)
    ],
    products: [
        .library(
            name: "MarkdownUI",
            targets: ["MarkdownUI"]
        ),
        .library(
            name: "NetworkImage",
            targets: ["NetworkImage"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-cmark", from: "0.4.0")
    ],
    targets: [
        // NetworkImage Target
        .target(
            name: "NetworkImage",
            path: "Sources/NetworkImage/Sources/NetworkImage"
        ),
        
        // MarkdownUI Target
        .target(
            name: "MarkdownUI",
            dependencies: [
                .product(name: "cmark-gfm", package: "swift-cmark"),
                .product(name: "cmark-gfm-extensions", package: "swift-cmark"),
                "NetworkImage"
            ],
            path: "Sources/MarkdownUI/Sources/MarkdownUI",
            exclude: [
                "Documentation.docc"
            ]
        )
    ]
)
