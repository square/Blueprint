import Foundation

// A context in which to evaluate whether or not two values are equivalent.
public enum EquivalencyContext: Hashable, Sendable, CaseIterable {

    /// The two values are identicial in every respect that could affect displayed output.
    case all

    // More fine-grained contexts:

    /// The two values are equivalent in all aspects that would affect the size of the element.
    /// - Warning:Non-obvious things may affect element-sizing – for example, setting a time zone may seem like something that would only affect date calculations, but can result in different text being displayed, and therefore affect sizing. Consider carefully whether you are truly affecting sizing or not.
    case elementSizing
}

public protocol ContextuallyEquivalent {

    /// Allows a type to express equivilancy within certain contexts. For example, an Environment that represents dark mode would be equivalent to an Environment that represents light mode in a `elementSizing` context, but not in `all` contexts.
    /// - Parameters:
    ///   - other: The instance of the type being compared against.
    ///   - context: The context to compare within.
    /// - Returns: Whether or not the other instance is equivalent in the specified context.
    /// - Note: Equivilancy within a given context is transitive – that is, if value A is equivalent to value B in a given context, and B is equivalent to C in that same context, A will be considered equivalent to C with that context.
    func isEquivalent(to other: Self?, in context: EquivalencyContext) -> Bool

}

extension ContextuallyEquivalent {

    /// Convenience equivalency check passing in .all for context.
    ///   - other: The instance of the type being compared against.
    /// - Returns: Whether or not the other instance is equivalent in all contexts.
    public func isEquivalent(to other: Self?) -> Bool {
        isEquivalent(to: other, in: .all)
    }

}

extension ContextuallyEquivalent {

    // Allows comparison between types which may or may not be equivalent.
    @_disfavoredOverload
    public func isEquivalent(to other: (any ContextuallyEquivalent)?, in context: EquivalencyContext) -> Bool {
        isEquivalent(to: other as? Self, in: context)
    }

}

// Default implementation that always returns strict equivalency.
extension ContextuallyEquivalent where Self: Equatable {

    public func isEquivalent(to other: Self?, in context: EquivalencyContext) -> Bool {
        self == other
    }

}

public struct AnyContextuallyEquivalent: ContextuallyEquivalent {

    let base: Any

    public init(_ value: some ContextuallyEquivalent) {
        base = value
    }

    public func isEquivalent(to other: AnyContextuallyEquivalent?, in context: EquivalencyContext) -> Bool {
        guard let base = (base as? any ContextuallyEquivalent) else { return false }
        return base.isEquivalent(to: other?.base as? any ContextuallyEquivalent, in: context)
    }

}

