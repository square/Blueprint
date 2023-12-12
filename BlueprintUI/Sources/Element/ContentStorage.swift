import CoreGraphics

/// The implementation of an `ElementContent`.
protocol ContentStorage {
    var childCount: Int { get }

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
