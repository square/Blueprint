import Foundation

/// Protocol that allows a value to be cached between layout passes.
public protocol CrossLayoutCacheable {

    /// Allows a type to express cacheability of a value within certain contexts. For example, an Environment that represents dark mode would be equivalent to an Environment that represents light mode in a `elementSizing` context, but not in `all` contexts.
    /// - Parameters:
    ///   - other: The instance of the type being compared against.
    ///   - context: The context to compare within.
    /// - Returns: Whether or not the other instance is equivalent in the specified context.
    /// - Note: Equivilancy within a given context is transitive – that is, if value A is equivalent to value B in a given context, and B is equivalent to C in that same context, A will be considered equivalent to C with that context.
    func isCacheablyEquivalent(to other: Self?, in context: CrossLayoutCacheableContext) -> Bool

}

extension CrossLayoutCacheable {

    /// Convenience equivalency check passing in .all for context.
    ///   - other: The instance of the type being compared against.
    /// - Returns: Whether or not the other instance is equivalent in all contexts.
    public func isCacheablyEquivalent(to other: Self?) -> Bool {
        isCacheablyEquivalent(to: other, in: .all)
    }

}

extension CrossLayoutCacheable {

    // Allows comparison between types which may or may not be equivalent.
    @_disfavoredOverload
    public func isCacheablyEquivalent(to other: (any CrossLayoutCacheable)?, in context: CrossLayoutCacheableContext) -> Bool {
        isCacheablyEquivalent(to: other as? Self, in: context)
    }

}

// Default implementation that always returns strict equivalency.
extension CrossLayoutCacheable where Self: Equatable {

    public func isCacheablyEquivalent(to other: Self?, in context: CrossLayoutCacheableContext) -> Bool {
        self == other
    }

}
