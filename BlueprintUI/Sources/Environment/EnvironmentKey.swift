/// Types conforming to this protocol can be used as keys in an `Environment`.
///
/// Using a type as the key allows us to strongly type each value, with the
/// key's `EnvironmentKey.Value` associated value.
///
/// ## Example
///
/// Usually a key is implemented with an uninhabited type, such an empty enum.
///
///     enum WidgetCountKey: EnvironmentKey {
///         static let defaultValue: Int = 0
///     }
///
/// You can write a small extension on `Environment` to make it easier to use your key.
///
///     extension Environment {
///         var widgetCount: Int {
///             get { self[WidgetCountKey.self] }
///             set { self[WidgetCountKey.self] = newValue }
///         }
///     }
public protocol EnvironmentKey {
    /// The type of value stored by this key.
    associatedtype Value

    /// The default value that will be vended by an `Environment` for this key if no other value
    /// has been set.
    static var defaultValue: Self.Value { get }


    /// Compares two environment values without direct conformance of the values.
    /// - Parameters:
    ///   - lhs: The left hand side value being compared.
    ///   - rhs: The right hand side value being compared.
    ///   - context: The context to evaluate the equivalency.
    /// - Returns: Whether or not the two values are equivalent in the specified context.
    static func isEquivalent(lhs: Value, rhs: Value, in context: EquivalencyContext) -> Bool

}

extension EnvironmentKey where Value: Equatable {

    public static func isEquivalent(lhs: Value, rhs: Value, in context: EquivalencyContext) -> Bool {
        lhs == rhs
    }

    /// Convenience implementation returning that the values are always equivalent in the specified contexts, and otherwise evaluates using Equality.
    /// - Parameters:
    ///   - contexts: Contexts in which to always return true for equivalency.
    ///   - lhs: The left hand side value being compared.
    ///   - rhs: The right hand side value being compared.
    ///   - evaluatingContext: The context in which the values are currently being compared.
    /// - Returns: Whether or not the two values are equivalent in the specified context.
    /// - Note: This is often used for convenience in cases where layout is unaffected, e.g., for an environment value like dark mode, which will have no effect on internal or external layout.
    public static func alwaysEquivalentIn(
        _ contexts: Set<EquivalencyContext>,
        lhs: Value,
        rhs: Value,
        evaluatingContext: EquivalencyContext
    ) -> Bool {
        if contexts.contains(evaluatingContext) {
            true
        } else {
            lhs == rhs
        }
    }

}

extension EnvironmentKey where Value: ContextuallyEquivalent {

    public static func isEquivalent(lhs: Value, rhs: Value, in context: EquivalencyContext) -> Bool {
        lhs.isEquivalent(to: rhs, in: context)
    }

    /// Convenience implementation returning that the values are always equivalent in the specified contexts, and otherwise evaluates using ContextuallyEquivalent.
    /// - Parameters:
    ///   - contexts: Contexts in which to always return true for equivalency.
    ///   - lhs: The left hand side value being compared.
    ///   - rhs: The right hand side value being compared.
    ///   - evaluatingContext: The context in which the values are currently being compared.
    /// - Returns: Whether or not the two values are equivalent in the specified context.
    /// - Note: This is often used for convenience in cases where layout is unaffected, e.g., for an environment value like dark mode, which will have no effect on internal or external layout.
    public static func alwaysEquivalentIn(
        _ contexts: Set<EquivalencyContext>,
        lhs: Value,
        rhs: Value,
        evaluatingContext: EquivalencyContext
    ) -> Bool {
        if contexts.contains(evaluatingContext) {
            true
        } else {
            lhs.isEquivalent(to: rhs, in: evaluatingContext)
        }
    }

}

extension EnvironmentKey {

    /// Convenience comparison to express default equality in specific contexts.
    /// - Parameters:
    ///   - contexts: The contexts in which the values are always equilvalent.
    ///   - evaluatingContext: The context being evaulated.
    /// - Returns: Whether or not the value is equivalent in the context.
    public static func alwaysEquivalentIn(
        _ contexts: Set<EquivalencyContext>,
        evaluatingContext: EquivalencyContext
    ) -> Bool {
        contexts.contains(evaluatingContext)
    }

}
