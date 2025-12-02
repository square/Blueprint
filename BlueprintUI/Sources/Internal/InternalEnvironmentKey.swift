import Foundation

/// An `EnvironmentKey` which is only stored in the internal storage of the `Environment`, and which does not participate in equivalency comparsions.
protocol InternalEnvironmentKey: EnvironmentKey {}

extension InternalEnvironmentKey {

    // Internal environment keys do not participate in equivalency checks.
    static func isCacheablyEquivalent(lhs: Value, rhs: Value, in context: CrossLayoutCacheableContext) -> Bool {
        true
    }

}
