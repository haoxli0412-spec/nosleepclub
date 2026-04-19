// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "nosleepclub",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "nosleepclub",
            path: "Sources",
            linkerSettings: [
                .linkedFramework("CoreGraphics"),
            ]
        ),
    ]
)
