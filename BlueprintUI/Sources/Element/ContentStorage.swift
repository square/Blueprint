import CoreGraphics

/// The implementation of an `ElementContent`.
protocol ContentStorage {
    var childCount: Int { get }

    func measure(
        in constraint: SizeConstraint,
        environment: Environment,
        cache: CacheTree
    ) -> CGSize

    func performLayout(
        attributes: LayoutAttributes,
        environment: Environment,
        cache: CacheTree
    ) -> [(identifier: ElementIdentifier, node: LayoutResultNode)]
}
