import Foundation

// A context in which to evaluate whether or not two values are equivalent.
public enum EquivalencyContext: Hashable, Sendable, CaseIterable {
    // The two values are identicial in every respect.
    case all
    // The two values are equivalent in all aspects that would affect layout.
    case overallLayout
    // The two values are equivalent in all aspects that would affect layout internally.
    case internalElementLayout
}

public protocol ContextuallyEquivalent {

    /// Allows a type to express equivilancy within certain contexts. For example, an Environment that represents dark mode would be equivilant to an Environment that represents light mode in a `layout` context, but not in `all` contexts.
    /// - Parameters:
    ///   - other: The instance of the type being compared against.
    ///   - context: The context to compare within.
    /// - Returns: Whether or not the other instance is equivalent in the specified context.
    func isEquivalent(to other: Self?, in context: EquivalencyContext) -> Bool

}


extension ContextuallyEquivalent {

    // Allows comparison between types which may or may not be equivalent.
    @_disfavoredOverload
    func isEquivalent(to other: (any ContextuallyEquivalent)?, in context: EquivalencyContext) -> Bool {
        isEquivalent(to: other as? Self, in: context)
    }

}

// Default implementation that always returns strict equivalency.
extension ContextuallyEquivalent where Self: Equatable {

    func isEquivalent(to other: Self?, in context: EquivalencyContext) -> Bool {
        self == other
    }

}
