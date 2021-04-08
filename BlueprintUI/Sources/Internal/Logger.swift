import Foundation
import os.log

/// Namespace for logging helpers
enum Logger { }

/// BlueprintView signposts
extension Logger {
    static func logLayoutStart(view: BlueprintView) {
        if #available(iOS 12.0, *) {
            os_signpost(
                .begin,
                log: .blueprint,
                name: "Layout",
                signpostID: OSSignpostID(log: .blueprint, object: view),
                "%{public}s",
                view.name ?? "BlueprintView"
            )
        }
    }

    static func logLayoutEnd(view: BlueprintView) {
        if #available(iOS 12.0, *) {
            os_signpost(
                .end,
                log: .blueprint,
                name: "Layout",
                signpostID: OSSignpostID(log: .blueprint, object: view)
            )
        }
    }

    static func logViewUpdateStart(view: BlueprintView) {
        if #available(iOS 12.0, *) {
            os_signpost(
                .begin,
                log: .blueprint,
                name: "View Update",
                signpostID: OSSignpostID(log: .blueprint, object: view),
                "%{public}s",
                view.name ?? "BlueprintView"
            )
        }
    }

    static func logViewUpdateEnd(view: BlueprintView) {
        if #available(iOS 12.0, *) {
            os_signpost(
                .end,
                log: .blueprint,
                name: "View Update",
                signpostID: OSSignpostID(log: .blueprint, object: view)
            )
        }
    }

    static func logElementAssigned(view: BlueprintView) {
        if #available(iOS 12.0, *) {
            os_signpost(
                .event,
                log: .blueprint,
                name: "Element assigned",
                signpostID: OSSignpostID(log: .blueprint, object: view),
                "Element assigned to %{public}s",
                view.name ?? "BlueprintView"
            )
        }
    }
}

/// Measuring signposts
extension Logger {
    static func logMeasureStart(object: AnyObject, description: String, constraint: SizeConstraint) {
        if #available(iOS 12.0, *) {
            os_signpost(
                .begin,
                log: .blueprint,
                name: "Measuring",
                signpostID: OSSignpostID(log: .blueprint, object: object),
                // nb: os_signpost seems to ignore precision specifiers
                "%{public}s in %.1f×%.1f",
                description,
                constraint.width.constrainedValue ?? .infinity,
                constraint.height.constrainedValue ?? .infinity
            )
        }
    }

    static func logMeasureEnd(object: AnyObject) {
        if #available(iOS 12.0, *) {
            os_signpost(
                .end,
                log: .blueprint,
                name: "Measuring",
                signpostID: OSSignpostID(log: .blueprint, object: object)
            )
        }
    }
}

