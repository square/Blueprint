import Foundation
import os.log

/// Namespace for logging helpers
enum Logger {

    private static let _signposter = OSSignposter(subsystem: "com.block.blueprint", category: "Blueprint")
    fileprivate static var signposter: OSSignposter? {
        guard BlueprintLogging.isEnabled else { return nil }
        return _signposter
    }


}

extension Logger {

    static func start(name: StaticString, view: BlueprintView) -> OSSignpostIntervalState? {
        signposter?.beginInterval(
            name,
            id: OSSignpostID(log: .active, object: view),
            "\(view.name ?? "BlueprintView", privacy: .public)"
        )
    }

    static func event(name: StaticString, object: AnyObject, description: String) {
        signposter?.emitEvent(
            name,
            id: OSSignpostID(log: .active, object: object),
            "\(description)"
        )
    }

}

/// BlueprintView signposts
extension Logger {

    static func logLayoutStart(view: BlueprintView) -> OSSignpostIntervalState? {
        start(name: "Layout", view: view)
    }

    static func logLayoutEnd(_ state: OSSignpostIntervalState?) {
        guard let state else { return }
        signposter?.endInterval("Layout", state)
    }

    static func logViewUpdateStart(view: BlueprintView) -> OSSignpostIntervalState? {
        start(name: "View Update", view: view)
    }

    static func logViewUpdateEnd(_ state: OSSignpostIntervalState?) {
        guard let state else { return }
        signposter?.endInterval("View Update", state)
    }

    static func logElementAssigned(view: BlueprintView) {
        event(name: "Element assigned", object: view, description: "Element assigned to \(view.name ?? "BlueprintView")")
    }

    static func logSizeThatFitsStart(
        view: BlueprintView,
        description: @autoclosure () -> String
    ) -> OSSignpostIntervalState? {
        let description = description()
        return signposter?.beginInterval(
            "View Sizing",
            id: OSSignpostID(log: .active, object: view),
            "\(description, privacy: .public)"
        )
    }

    static func logSizeThatFitsEnd(_ state: OSSignpostIntervalState?) {
        guard let state else { return }
        signposter?.endInterval("View Update", state)
    }

}

/// Measuring signposts
extension Logger {

    static func logMeasureStart(object: AnyObject, description: String, constraint: SizeConstraint) -> OSSignpostIntervalState? {
        guard BlueprintLogging.config.recordElementMeasures else { return nil }
        return signposter?.beginInterval(
            "Measuring",
            id: OSSignpostID(log: .active, object: object),
            "\(description, privacy: .public) in \(constraint.width.logDescription, privacy: .public)x\(constraint.height.logDescription, privacy: .public)"
        )
    }

    static func logMeasureEnd(_ state: OSSignpostIntervalState?) {
        guard BlueprintLogging.config.recordElementMeasures else { return }
        guard let state else { return }
        signposter?.endInterval("Measuring", state)
    }

    static func logCacheHit(object: AnyObject, description: @autoclosure () -> String, constraint: SizeConstraint) {
        guard BlueprintLogging.config.recordElementMeasures else { return }
        let description = description()
        event(
            name: "Cache hit",
            object: object,
            description: "\(description) in \(constraint.width.logDescription)x\(constraint.height.logDescription)"
        )
    }

    static func logCacheMiss(object: AnyObject, description: @autoclosure () -> String, constraint: SizeConstraint) {
        guard BlueprintLogging.config.recordElementMeasures else { return }
        let description = description()
        event(
            name: "Cache miss",
            object: object,
            description: "\(description) in \(constraint.width.logDescription)x\(constraint.height.logDescription)"
        )
    }

    static func logCacheUnconstrainedSearchMatch(
        object: AnyObject,
        description: @autoclosure () -> String,
        constraint: SizeConstraint,
        match: @autoclosure () -> SizeConstraint
    ) {
        guard BlueprintLogging.config.recordElementMeasures else { return }

        let match = match()

        let description = description()
        event(
            name: "Cache unconstrained search match",
            object: object,
            description: "\(description) in \(constraint.width.logDescription)x\(constraint.height.logDescription) matched \(match.width.logDescription)x\(match.height.logDescription)"
        )
    }

}

extension SizeConstraint.Axis {

    var logDescription: String {
        if let constrainedValue {
            Double(constrainedValue).formatted(.number.precision(.fractionLength(0..<1)))
        } else {
            CGFloat.infinity.formatted()
        }
    }

}
