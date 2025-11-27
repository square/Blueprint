import Foundation
import os.log

/// Namespace for logging helpers
enum Logger {
    fileprivate static var signposter: OSSignposter {
        OSSignposter(logHandle: .active)
    }
    static var hook: ((String) -> Void)?
}

// MARK: - BlueprintView signposts
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

// MARK: - HintingSizeCache signposts

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



}

// MARK: - HostingViewContext

extension Logger {

    // MARK: Environment Comparison

    static func logEnvironmentKeySetEquivalencyComparisonStart(key: some Hashable) -> OSSignpostIntervalState? {
        guard BlueprintLogging.isEnabled else { return nil }
        let token = signposter.beginInterval(
            "Environment key set equivalency comparison",
            id: key.signpost,
            "Start: \(String(describing: key))"
        )
        hook?("\(#function) \(String(describing: key))")
        return token
    }

    static func logEnvironmentKeySetEquivalencyComparisonEnd(_ token: OSSignpostIntervalState?, key: some Hashable) {
        guard BlueprintLogging.isEnabled, let token else { return }
        signposter.endInterval("Environment key set equivalency comparison", token, "\(String(describing: key))")
        hook?("\(#function) \(String(describing: key))")
    }

    static func logEnvironmentEquivalencyComparisonStart(environment: Environment) -> OSSignpostIntervalState? {
        guard BlueprintLogging.isEnabled else { return nil }
        let token = signposter.beginInterval(
            "Environment equivalency comparison",
            id: environment.fingerprint.value.signpost,
            "Start: \(String(describing: environment))"
        )
        hook?("\(#function) \(environment.fingerprint)")
        return token
    }

    static func logEnvironmentEquivalencyComparisonEnd(_ token: OSSignpostIntervalState?, environment: Environment) {
        guard BlueprintLogging.isEnabled, let token else { return }
        signposter.endInterval("Environment equivalency comparison", token, "\(String(describing: environment))")
        hook?("\(#function) \(environment.fingerprint)")
    }

    static func logEnvironmentEquivalencyFingerprintEqual(environment: Environment) {
        guard BlueprintLogging.isEnabled else { return }
        signposter.emitEvent("Environments trivially equal from fingerprint", id: environment.fingerprint.value.signpost)
        hook?("\(#function) \(environment.fingerprint)")
    }

    static func logEnvironmentEquivalencyFingerprintCacheHit(environment: Environment) {
        guard BlueprintLogging.isEnabled else { return }
        signposter.emitEvent("Environment cached comparison result hit", id: environment.fingerprint.value.signpost)
        hook?("\(#function) \(environment.fingerprint)")
    }

    static func logEnvironmentEquivalencyFingerprintCacheMiss(environment: Environment) {
        guard BlueprintLogging.isEnabled else { return }
        signposter.emitEvent("Environment cached comparison result miss", id: environment.fingerprint.value.signpost)
        hook?("\(#function) \(environment.fingerprint)")
    }

    static func logEnvironmentEquivalencyCompletedWithNonEquivalence(
        environment: Environment,
        key: some Hashable,
        context: CrossLayoutCacheableContext
    ) {
        guard BlueprintLogging.isEnabled else { return }
        signposter.emitEvent(
            "Environment equivalency completed with non-equivalent result",
            id: environment.fingerprint.value.signpost,
            "\(String(describing: context)): \(String(describing: key)) not equivalent"
        )
        hook?("\(#function) \(String(describing: key))")
    }

    static func logEnvironmentEquivalencyCompletedWithEquivalence(environment: Environment, context: CrossLayoutCacheableContext) {
        guard BlueprintLogging.isEnabled else { return }
        signposter.emitEvent(
            "Environment equivalency completed with equivalent result",
            id: environment.fingerprint.value.signpost,
            "\(String(describing: context))"
        )
        hook?("\(#function) \(environment.fingerprint)")
    }


    // MARK: ValidatingCache

    static func logValidatingCacheValidationStart(key: some Hashable) -> OSSignpostIntervalState? {
        guard BlueprintLogging.isEnabled else { return nil }
        let token = signposter.beginInterval(
            "ValidatingCache validation",
            id: key.signpost,
            "Start: \(String(describing: key))"
        )
        hook?("\(#function) \(String(describing: key))")
        return token
    }

    static func logValidatingCacheValidationEnd(_ token: OSSignpostIntervalState?, key: some Hashable) {
        guard BlueprintLogging.isEnabled, let token else { return }
        signposter.endInterval("ValidatingCache validation", token, "\(String(describing: key))")
        hook?("\(#function) \(String(describing: key))")
    }

    static func logValidatingCacheFreshValueCreationStart(key: some Hashable) -> OSSignpostIntervalState? {
        guard BlueprintLogging.isEnabled else { return nil }
        let token = signposter.beginInterval(
            "ValidatingCache fresh value creation",
            id: key.signpost,
            "\(String(describing: key))"
        )
        hook?("\(#function) \(String(describing: key))")
        return token
    }

    static func logValidatingCacheFreshValueCreationEnd(_ token: OSSignpostIntervalState?, key: some Hashable) {
        guard BlueprintLogging.isEnabled, let token else { return }
        signposter.endInterval("ValidatingCache fresh value creation", token)
        hook?("\(#function) \(String(describing: key))")
    }

    static func logValidatingCrossLayoutCacheKeyMiss(key: some Hashable) {
        guard BlueprintLogging.isEnabled else { return }
        signposter.emitEvent("ValidatingCache key miss", id: key.signpost)
        hook?("\(#function) \(String(describing: key))")
    }

    static func logValidatingCrossLayoutCacheKeyHit(key: some Hashable) {
        guard BlueprintLogging.isEnabled else { return }
        signposter.emitEvent("ValidatingCache key hit", id: key.signpost)
        hook?("\(#function) \(String(describing: key))")
    }

    static func logValidatingCacheHitAndValidationSuccess(key: some Hashable) {
        guard BlueprintLogging.isEnabled else { return }
        signposter.emitEvent("ValidatingCache validation success", id: key.signpost)
        hook?("\(#function) \(String(describing: key))")
    }

    static func logValidatingCacheHitAndValidationFailure(key: some Hashable) {
        guard BlueprintLogging.isEnabled else { return }
        signposter.emitEvent("ValidatingCache validation failure", id: key.signpost)
        hook?("\(#function) \(String(describing: key))")
    }

}

extension Hashable {

    fileprivate var signpost: OSSignpostID {
        OSSignpostID(UInt64(abs(hashValue)))
    }

}

// MARK: - Utilities

extension Logger {
    private static func shouldRecordMeasurePass() -> Bool {
        BlueprintLogging.isEnabled &&
            BlueprintLogging.config.recordElementMeasures
    }

}
