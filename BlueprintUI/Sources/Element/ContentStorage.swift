import CoreGraphics

/// The implementation of an `ElementContent`.
protocol ContentStorage: LegacyContentStorage, CaffeinatedContentStorage {
    var childCount: Int { get }
}

protocol LegacyContentStorage {
    func measure(
        in constraint: SizeConstraint,
        environment: Environment,
        cache: CacheTree
    ) -> CGSize

    func performLegacyLayout(
        attributes: LayoutAttributes,
        environment: Environment,
        cache: CacheTree
    ) -> [ElementContent.IdentifiedNode]
}

protocol CaffeinatedContentStorage {
    func sizeThatFits(
        proposal: SizeConstraint,
        environment: Environment,
        node: LayoutTreeNode
    ) -> CGSize

    func performCaffeinatedLayout(
        frame: CGRect,
        environment: Environment,
        node: LayoutTreeNode
    ) -> [ElementContent.IdentifiedNode]
}
