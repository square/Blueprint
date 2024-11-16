import ProjectDescription
import ProjectDescriptionHelpers

let workspace = Workspace(
    name: "Development",
    projects: ["."],
    schemes: [
        // Generate a scheme for each target in Package.swift for convenience
        .blueprint("BlueprintUI"),
        .blueprint("BlueprintUICommonControls"),
    ]
)

extension Scheme {
    public static func blueprint(_ target: String) -> Self {
        .scheme(
            name: target,
            buildAction: .buildAction(targets: [.project(path: "..", target: target)])
        )
    }
}
