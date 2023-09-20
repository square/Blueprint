import Foundation

/// Configuration options for ``LayoutMode/caffeinated``.
///
/// Generally these are only useful for experimenting with the performance profile of different
/// element compositions, and you should stick with ``default``.
public struct LayoutOptions: Equatable {

    /// The default configuration.
    public static let `default` = LayoutOptions(
        hintRangeBoundaries: true,
        searchUnconstrainedKeys: true,
        assumeStableSubelements: true
    )

    /// Enables aggressive cache hinting along the boundaries of the range between constraints and
    /// measured sizes. Requires elements to conform to the Caffeinated Layout contract for correct
    /// behavior.
    public var hintRangeBoundaries: Bool

    /// Allows cache misses on finite constraints to deduce a range-based match by searching for a
    /// hit on the unconstrained value for each axis. Requires elements to adhere to the Caffeinated
    /// Layout contract for correct behavior.
    public var searchUnconstrainedKeys: Bool

    public var assumeStableSubelements: Bool

    public init(
        hintRangeBoundaries: Bool,
        searchUnconstrainedKeys: Bool,
        assumeStableSubelements: Bool = true
    ) {
        self.hintRangeBoundaries = hintRangeBoundaries
        self.searchUnconstrainedKeys = searchUnconstrainedKeys
        self.assumeStableSubelements = assumeStableSubelements
    }
}
