// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Go2Claude",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "Go2ClaudeCore",
            targets: ["Go2ClaudeCore"]
        ),
        .executable(
            name: "Go2Claude",
            targets: ["Go2Claude"]
        ),
        .executable(
            name: "Go2ClaudeToolbar",
            targets: ["Go2ClaudeToolbar"]
        )
    ],
    targets: [
        .target(
            name: "Go2ClaudeCore"
        ),
        .executableTarget(
            name: "Go2Claude",
            dependencies: ["Go2ClaudeCore"]
        ),
        .executableTarget(
            name: "Go2ClaudeToolbar",
            dependencies: ["Go2ClaudeCore"]
        ),
        .testTarget(
            name: "Go2ClaudeCoreTests",
            dependencies: ["Go2ClaudeCore"]
        ),
        .testTarget(
            name: "Go2ClaudeAppTests",
            dependencies: ["Go2Claude"]
        ),
        .testTarget(
            name: "Go2ClaudeToolbarTests",
            dependencies: ["Go2ClaudeToolbar", "Go2ClaudeCore"]
        )
    ]
)
