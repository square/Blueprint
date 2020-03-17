// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BlueprintUI",
    platforms: [
        .iOS("10.0"),
    ],
    products: [
        .library(
            name: "BlueprintUI",
            targets: ["BlueprintUI"]),
        .library(
            name: "BlueprintUICommonControls",
            targets: ["BlueprintUICommonControls"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "BlueprintUI",
            path: "BlueprintUI/Sources"),
        .testTarget(
            name: "BlueprintUITests",
            dependencies: ["BlueprintUI"],
            path: "BlueprintUI/Tests"),
        .target(
            name: "BlueprintUICommonControls",
            dependencies: ["BlueprintUI"],
            path: "BlueprintUICommonControls/Sources"),
        .testTarget(
            name: "BlueprintUICommonControlsTests",
            dependencies: ["BlueprintUICommonControls"],
            path: "BlueprintUICommonControls/Tests"),
    ],
    swiftLanguageVersions: [.v5]
)
