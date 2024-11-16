import Foundation
import ProjectDescription

public let blueprintBundleIdPrefix = "com.squareup.blueprint"
public let blueprintDestinations: ProjectDescription.Destinations = .iOS
public let blueprintDeploymentTargets: DeploymentTargets = .iOS("15.0")

public let blueprintDependencies: [TargetDependency] = [
    .external(name: "BlueprintUI"),
    .external(name: "BlueprintUICommonControls"),
]

extension String {
    var bundleId: String {
        replacing(try! Regex("[^A-Za-z0-9-\\.]")) { _ in "" }
    }

    var productName: String {
        replacing(try! Regex("[^A-Za-z0-9-\\._]")) { _ in "" }
    }
}

extension Target {

    public static func app(
        name: String,
        sources: ProjectDescription.SourceFilesList,
        resources: ProjectDescription.ResourceFileElements? = nil,
        dependencies: [TargetDependency] = blueprintDependencies
    ) -> Self {
        .target(
            name: name,
            destinations: blueprintDestinations,
            product: .app,
            productName: name.productName,
            bundleId: "\(blueprintBundleIdPrefix).\(name.bundleId)",
            deploymentTargets: blueprintDeploymentTargets,
            infoPlist: .extendingDefault(
                with: [
                    "UILaunchScreen": ["UIColorName": ""],
                ]
            ),
            sources: sources,
            resources: resources,
            dependencies: dependencies
        )
    }

    public static func target(
        name: String,
        sources: ProjectDescription.SourceFilesList? = nil,
        resources: ProjectDescription.ResourceFileElements? = nil,
        dependencies: [TargetDependency] = blueprintDependencies
    ) -> Self {
        .target(
            name: name,
            destinations: blueprintDestinations,
            product: .framework,
            bundleId: "\(blueprintBundleIdPrefix).\(name.bundleId)",
            deploymentTargets: blueprintDeploymentTargets,
            sources: sources ?? "\(name)/Sources/**",
            resources: resources,
            dependencies: dependencies
        )
    }

    public static func unitTest(
        for moduleUnderTest: String,
        testName: String = "Tests",
        sources: ProjectDescription.SourceFilesList? = nil,
        resources: ProjectDescription.ResourceFileElements? = nil,
        dependencies: [TargetDependency] = blueprintDependencies,
        environmentVariables: [String: EnvironmentVariable] = [:]
    ) -> Self {
        let name = "\(moduleUnderTest)-\(testName)"
        return .target(
            name: name,
            destinations: blueprintDestinations,
            product: .unitTests,
            bundleId: "\(blueprintBundleIdPrefix).\(name.bundleId)",
            deploymentTargets: blueprintDeploymentTargets,
            sources: sources ?? "../\(moduleUnderTest)/\(testName)/**",
            resources: resources,
            dependencies: dependencies,
            environmentVariables: environmentVariables
        )
    }
}
