// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Development",
    dependencies: [
        .package(path: "../../"),
        .package(
            url: "https://github.com/cashapp/AccessibilitySnapshot.git",
            from: "0.4.1"
        ),
        .package(
            url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
            from: "1.18.0"
        ),
    ]
)
