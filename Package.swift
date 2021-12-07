// swift-tools-version:5.2
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
            name: "libcmark",
            dependencies: [],
            path: "cmark",
            exclude: [
                "include",
                "case_fold_switch.inc",
                "entities.inc",
                "COPYING",
            ],
            publicHeadersPath: "./"
        ),
        .target(
            name: "BlueprintUI",
            dependencies: ["libcmark"],
            path: "BlueprintUI/Sources",
            exclude: ["BlueprintUI.h"]
        ),
        .testTarget(
            name: "BlueprintUITests",
            dependencies: ["BlueprintUI"],
            path: "BlueprintUI/Tests"
        ),
        .target(
            name: "BlueprintUICommonControls",
            dependencies: ["BlueprintUI", "libcmark"],
            path: "BlueprintUICommonControls/Sources"
        ),
        .testTarget(
            name: "BlueprintUICommonControlsTests",
            dependencies: ["BlueprintUICommonControls"],
            path: "BlueprintUICommonControls/Tests"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
