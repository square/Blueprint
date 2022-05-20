// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BlueprintUI",
    platforms: [
        .iOS(.v12),
    ],
    products: [
        .library(
            name: "BlueprintUI",
            targets: ["BlueprintUI"]
        ),
        .library(
            name: "BlueprintUICommonControls",
            targets: ["BlueprintUICommonControls"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.48.11"),
    ],
    targets: [
        .target(
            name: "BlueprintUI",
            path: "BlueprintUI/Sources",
            swiftSettings: [.unsafeFlags(["-enable-testing"])]
        ),
        .testTarget(
            name: "BlueprintUITests",
            dependencies: ["BlueprintUI"],
            path: "BlueprintUI/Tests"
        ),
        .target(
            name: "BlueprintUICommonControls",
            dependencies: ["BlueprintUI"],
            path: "BlueprintUICommonControls/Sources",
            swiftSettings: [.unsafeFlags(["-enable-testing"])]
        ),
        .testTarget(
            name: "BlueprintUICommonControlsTests",
            dependencies: ["BlueprintUICommonControls"],
            path: "BlueprintUICommonControls/Tests/Sources",
            resources: [
                .process("Resources/test-image.jpg"),
                .copy("Resources/ReferenceImages"),
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
