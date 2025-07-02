import CoreGraphics

/// The implementation of an `ElementContent`.
protocol ContentStorage: CaffeinatedContentStorage {
    var childCount: Int { get }
}

protocol CaffeinatedContentStorage {
    func sizeThatFits(
        proposal: SizeConstraint,
        environment: Environment,
        node: LayoutTreeNode,
        cache: CrossLayoutSizeCache?
    ) -> CGSize

    func performCaffeinatedLayout(
        frame: CGRect,
        environment: Environment,
        node: LayoutTreeNode
    ) -> [ElementContent.IdentifiedNode]
}
