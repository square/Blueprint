import Foundation
import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "Development",
    settings: .settings(base: ["ENABLE_MODULE_VERIFIER": "YES"]),
    targets: [

        .app(
            name: "SampleApp",
            sources: ["Sources/**"]
        ),

        .app(
            name: "Tutorial 1",
            sources: ["Tutorials/Tutorial 1/**"]
        ),
        .app(
            name: "Tutorial 1 (Completed)",
            sources: ["Tutorials/Tutorial 1 (Completed)/**"]
        ),
        .app(
            name: "Tutorial 2",
            sources: ["Tutorials/Tutorial 2/**"]
        ),
        .app(
            name: "Tutorial 2 (Completed)",
            sources: ["Tutorials/Tutorial 2 (Completed)/**"]
        ),
        .app(
            name: "BlueprintUI_TestHost",
            sources: ["../BlueprintUI/UITests/UITestHost/**"]
        ),
        .app(
            name: "BlueprintUICommonControls_TestHost",
            sources: ["../BlueprintUICommonControls/UITests/UITestHost/**"]
        ),

        // These tests are duplicates of the test definitions in the root Package.swift, but Tuist
        // does not currently support creating targets for tests in SwiftPM dependencies. See
        // https://github.com/tuist/tuist/issues/5912

        .unitTest(
            for: "BlueprintUI"
        ),

        .target(
            name: "BlueprintUI_UITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "$(inherited).UITests",
            deploymentTargets: .iOS("15.0"),
            sources: ["../BlueprintUI/Tests/Extensions/**", "../BlueprintUI/UITests/**"],
            dependencies: [.target(name: "BlueprintUI_TestHost")]
        ),

        .target(
            name: "BlueprintUICommonControls_UITests",
            destinations: .iOS,
            product: .uiTests,
            bundleId: "$(inherited).UITests",
            deploymentTargets: .iOS("15.0"),
            sources: ["../BlueprintUI/Tests/Extensions/**", "../BlueprintUICommonControls/UITests/**"],
            dependencies: [.target(name: "BlueprintUICommonControls_TestHost")]
        ),

        .unitTest(
            for: "BlueprintUICommonControls",
            resources: [
                .glob(
                    pattern: "../BlueprintUICommonControls/Tests/Sources/Resources/*"
                ),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "UnitTests",
            testAction: .targets(
                [
                    "BlueprintUI-Tests",
                    "BlueprintUICommonControls-Tests",
                    "BlueprintUI_UITests",
                    "BlueprintUICommonControls_UITests",
                ]
            )
        ),
    ],
    additionalFiles: [
        "../CHANGELOG.md",
    ]
)
