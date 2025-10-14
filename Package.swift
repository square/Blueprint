// swift-tools-version:6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BlueprintUI",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
        .macCatalyst(.v15),
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
        .library(
            name: "BlueprintUIAccessibilityCore",
            targets: ["BlueprintUIAccessibilityCore"]
        ),
    ],
    targets: [
        .target(
            name: "BlueprintUI",
            path: "BlueprintUI/Sources"
            // Enable this setting to allow running tests in release mode.
            // swiftSettings: [.unsafeFlags(["-enable-testing"])]
        ),
        .testTarget(
            name: "BlueprintUITests",
            dependencies: ["BlueprintUI"],
            path: "BlueprintUI/Tests"
        ),
        .target(
            name: "BlueprintUICommonControls",
            dependencies: ["BlueprintUI", "BlueprintUIAccessibilityCore"],
            path: "BlueprintUICommonControls/",
            sources: ["Sources"]
            // Enable this setting to allow running tests in release mode.
            // swiftSettings: [.unsafeFlags(["-enable-testing"])]
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
        .target(
            name: "BlueprintUIAccessibilityCore",
            dependencies: ["BlueprintUI"],
            path: "BlueprintUIAccessibilityCore/",
            sources: ["Sources"],
            resources: [
                .process("Resources"),
            ],
        ),
        .testTarget(
            name: "BlueprintUIAccessibilityCoreTests",
            dependencies: ["BlueprintUIAccessibilityCore"],
            path: "BlueprintUIAccessibilityCore/Tests"
        ),
    ],
    swiftLanguageModes: [.v5]
)
