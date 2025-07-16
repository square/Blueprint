import Foundation

/// An EnvironmentKey
protocol InternalEnvironmentKey: EnvironmentKey {}

extension InternalEnvironmentKey {

    // Internal environment keys do not participate in equivalency checks.
    static func isEquivalent(lhs: Value, rhs: Value, in context: EquivalencyContext) -> Bool {
        true
    }

}
