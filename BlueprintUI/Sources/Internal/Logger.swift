import Foundation
import os.log

/// Namespace for logging helpers
enum Logger {

    private static let _signposter = OSSignposter()
    fileprivate static var signposter: OSSignposter? {
        guard BlueprintLogging.isEnabled else { return nil }
        return signposter
    }


}

extension Logger {

    static func start(name: StaticString, view: BlueprintView) -> OSSignpostIntervalState? {
        guard let signposter else { return nil }
        return signposter.beginInterval(
            name,
            id: signposter.makeSignpostID(from: view),
            "\(view.name ?? "BlueprintView", privacy: .public)"
        )
    }

    static func event(name: StaticString, object: AnyObject, description: String) {
        guard let signposter else { return }
        signposter.emitEvent(
            name,
            id: signposter.makeSignpostID(from: object),
            "\(description)"
        )
    }

}

/// BlueprintView signposts
extension Logger {

    @discardableResult static func logLayoutStart(view: BlueprintView) -> OSSignpostIntervalState? {
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
        start(name: "Element assigned", view: view)
    }

    static func logSizeThatFitsStart(
        view: BlueprintView,
        description: @autoclosure () -> String
    ) -> OSSignpostIntervalState? {
        guard let signposter else { return nil }
        let description = description()
        return signposter.beginInterval(
            "View Sizing",
            id: signposter.makeSignpostID(from: view),
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
        guard shouldRecordMeasurePass() else { return nil }
        return signposter?.beginInterval(
            "Measuring",
            id: OSSignpostID(log: .active, object: object),
            "\(description, privacy: .public) in \(constraint.width.constrainedValue ?? .infinity, privacy: .public)x\(constraint.height.constrainedValue ?? .infinity, privacy: .public)"
        )
    }

    static func logMeasureEnd(_ state: OSSignpostIntervalState?) {
        guard shouldRecordMeasurePass() else { return }
        guard let state else { return }
        signposter?.endInterval("Measuring", state)
    }

    static func logCacheHit(object: AnyObject, description: @autoclosure () -> String, constraint: SizeConstraint) {
        guard shouldRecordMeasurePass() else { return }
        let description = description()
        // FIXME: CHECK REDACT
        // FIXME: PRECISIION
        event(
            name: "Cache hit",
            object: object,
            description: "\(description) in \(constraint.width.constrainedValue ?? .infinity)x\(constraint.height.constrainedValue ?? .infinity)"
        )
    }

    static func logCacheMiss(object: AnyObject, description: @autoclosure () -> String, constraint: SizeConstraint) {
        guard shouldRecordMeasurePass() else { return }
        let description = description()
        // FIXME: CHECK REDACT
        // FIXME: PRECISIION
        event(
            name: "Cache miss",
            object: object,
            description: "\(description) in \(constraint.width.constrainedValue ?? .infinity)x\(constraint.height.constrainedValue ?? .infinity)"
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

        let description = description()
        // FIXME: CHECK REDACT
        // FIXME: PRECISIION
        event(
            name: "Cache unconstrained search match",
            object: object,
            description: "\(description) in \(constraint.width.constrainedValue ?? .infinity)x\(constraint.height.constrainedValue ?? .infinity) matched \(match.width.constrainedValue ?? .infinity)x\(match.height.constrainedValue ?? .infinity)"
        )
    }

    // MARK: Utilities

    private static func shouldRecordMeasurePass() -> Bool {
        BlueprintLogging.isEnabled &&
            BlueprintLogging.config.recordElementMeasures
    }
}
