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
        description: @autoclosure () -> String
    ) {
        guard BlueprintLogging.isEnabled else { return }

        os_signpost(
            .begin,
            log: .active,
            name: "View Sizing",
            signpostID: OSSignpostID(log: .active, object: view),
            "%{public}s",
            description()
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

    static func logCacheHit(object: AnyObject, description: @autoclosure () -> String, constraint: SizeConstraint) {
        guard shouldRecordMeasurePass() else { return }

        os_signpost(
            .event,
            log: .active,
            name: "Cache hit",
            signpostID: OSSignpostID(log: .active, object: object),
            "%{public}s in %{public}s×%{public}s",
            description(),
            String(format: "%.1f", constraint.width.constrainedValue ?? .infinity),
            String(format: "%.1f", constraint.height.constrainedValue ?? .infinity)
        )
    }

    static func logCacheMiss(object: AnyObject, description: @autoclosure () -> String, constraint: SizeConstraint) {
        guard shouldRecordMeasurePass() else { return }

        os_signpost(
            .event,
            log: .active,
            name: "Cache miss",
            signpostID: OSSignpostID(log: .active, object: object),
            "%{public}s in %{public}s×%{public}s",
            description(),
            String(format: "%.1f", constraint.width.constrainedValue ?? .infinity),
            String(format: "%.1f", constraint.height.constrainedValue ?? .infinity)
        )
    }

    static func logCacheUnconstrainedSearchMatch(
        object: AnyObject,
        description: @autoclosure () -> String,
        constraint: SizeConstraint,
        match: @autoclosure () -> SizeConstraint
    ) {
        guard shouldRecordMeasurePass() else { return }

        let match = match()

        os_signpost(
            .event,
            log: .active,
            name: "Cache unconstrained search match",
            signpostID: OSSignpostID(log: .active, object: object),
            "%{public}s in %{public}s×%{public}s matched %{public}s×%{public}s",
            description(),
            String(format: "%.1f", constraint.width.constrainedValue ?? .infinity),
            String(format: "%.1f", constraint.height.constrainedValue ?? .infinity),
            String(format: "%.1f", match.width.constrainedValue ?? .infinity),
            String(format: "%.1f", match.height.constrainedValue ?? .infinity)
        )
    }

    // MARK: Utilities

    private static func shouldRecordMeasurePass() -> Bool {
        BlueprintLogging.isEnabled &&
            BlueprintLogging.config.recordElementMeasures
    }
}
