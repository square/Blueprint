import Foundation

/// Configuration options for ``LayoutMode/caffeinated``.
///
/// Generally these are only useful for experimenting with the performance profile of different
/// element compositions, and you should stick with ``default``.
public struct LayoutOptions: Hashable {

    /// The default configuration.
    public static let `default` = LayoutOptions(
        hintRangeBoundaries: true,
        searchUnconstrainedKeys: true,
        measureableStorageCache: true,
        stringNormalizationCache: true,
        skipUnneededSetNeedsViewHierarchyUpdates: true,
        labelAttributedStringCache: true
    )

    /// Enables aggressive cache hinting along the boundaries of the range between constraints and
    /// measured sizes. Requires elements to conform to the Caffeinated Layout contract for correct
    /// behavior.
    public var hintRangeBoundaries: Bool

    /// Allows cache misses on finite constraints to deduce a range-based match by searching for a
    /// hit on the unconstrained value for each axis. Requires elements to adhere to the Caffeinated
    /// Layout contract for correct behavior.
    public var searchUnconstrainedKeys: Bool

    /// Allows caching the results of `MeasurableStorage` `sizeThatFits`.
    public var measureableStorageCache: Bool

    /// Caches results of AttributedLabel normalization process.
    public var stringNormalizationCache: Bool

    /// Allows skipping calls to setNeedsViewHierarchyUpdates when updating Environment, if the environment is
    /// equilvalent to the prior value.
    public var skipUnneededSetNeedsViewHierarchyUpdates: Bool

    /// Caches MarketLabel attributed string generation
    public var labelAttributedStringCache: Bool

    public init(
        hintRangeBoundaries: Bool,
        searchUnconstrainedKeys: Bool,
        measureableStorageCache: Bool,
        stringNormalizationCache: Bool,
        skipUnneededSetNeedsViewHierarchyUpdates: Bool,
        labelAttributedStringCache: Bool
    ) {
        self.hintRangeBoundaries = hintRangeBoundaries
        self.searchUnconstrainedKeys = searchUnconstrainedKeys
        self.measureableStorageCache = measureableStorageCache
        self.stringNormalizationCache = stringNormalizationCache
        self.skipUnneededSetNeedsViewHierarchyUpdates = skipUnneededSetNeedsViewHierarchyUpdates
        self.labelAttributedStringCache = labelAttributedStringCache
    }
}
