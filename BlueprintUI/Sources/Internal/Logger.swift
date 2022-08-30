import Foundation
import os.log

/// Namespace for logging helpers
enum Logger {}

/// BlueprintView signposts
extension Logger {
    static func logLayoutStart(view: BlueprintView) {

        guard BlueprintLogging.isEnabled else { return }

        os_signpost(
            .begin,
            log: .active,
            name: "Layout",
            signpostID: OSSignpostID(log: .active, object: view),
            "%{public}s",
            view.name ?? "BlueprintView"
        )
    }

    static func logLayoutEnd(view: BlueprintView) {

        guard BlueprintLogging.isEnabled else { return }

        os_signpost(
            .end,
            log: .active,
            name: "Layout",
            signpostID: OSSignpostID(log: .active, object: view)
        )
    }

    static func logViewUpdateStart(view: BlueprintView) {

        guard BlueprintLogging.isEnabled else { return }

        os_signpost(
            .begin,
            log: .active,
            name: "View Update",
            signpostID: OSSignpostID(log: .active, object: view),
            "%{public}s",
            view.name ?? "BlueprintView"
        )
    }

    static func logViewUpdateEnd(view: BlueprintView) {

        guard BlueprintLogging.isEnabled else { return }

        os_signpost(
            .end,
            log: .active,
            name: "View Update",
            signpostID: OSSignpostID(log: .active, object: view)
        )
    }

    static func logElementAssigned(view: BlueprintView) {

        guard BlueprintLogging.isEnabled else { return }

        os_signpost(
            .event,
            log: .active,
            name: "Element assigned",
            signpostID: OSSignpostID(log: .active, object: view),
            "Element assigned to %{public}s",
            view.name ?? "BlueprintView"
        )
    }

    static func logSizeThatFitsStart(
        view: BlueprintView,
        description: String
    ) {
        guard BlueprintLogging.isEnabled else { return }

        os_signpost(
            .begin,
            log: .active,
            name: "View Sizing",
            signpostID: OSSignpostID(log: .active, object: view),
            "%{public}s",
            description
        )
    }

    static func logSizeThatFitsEnd(view: BlueprintView) {
        guard BlueprintLogging.isEnabled else { return }

        os_signpost(
            .end,
            log: .active,
            name: "View Sizing",
            signpostID: OSSignpostID(log: .active, object: view)
        )
    }
}

/// Measuring signposts
extension Logger {
    static func logMeasureStart(object: AnyObject, description: String, constraint: SizeConstraint) {

        guard shouldRecordMeasurePass() else { return }

        os_signpost(
            .begin,
            log: .active,
            name: "Measuring",
            signpostID: OSSignpostID(log: .active, object: object),
            // nb: os_signpost seems to ignore precision specifiers
            "%{public}s in %.1f×%.1f",
            description,
            constraint.width.constrainedValue ?? .infinity,
            constraint.height.constrainedValue ?? .infinity
        )
    }

    static func logMeasureEnd(object: AnyObject) {

        guard shouldRecordMeasurePass() else { return }

        os_signpost(
            .end,
            log: .active,
            name: "Measuring",
            signpostID: OSSignpostID(log: .active, object: object)
        )
    }

    // MARK: Utilities

    private static func shouldRecordMeasurePass() -> Bool {
        BlueprintLogging.isEnabled &&
            BlueprintLogging.config.recordMeasurePasses
    }
}
