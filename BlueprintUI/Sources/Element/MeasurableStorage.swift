import CoreGraphics

/// Content storage for leaf nodes.
struct MeasurableStorage: ContentStorage {

    typealias IdentifiedNode = ElementContent.IdentifiedNode

    let childCount = 0

    let measurer: (SizeConstraint, Environment) -> CGSize
}

extension MeasurableStorage: CaffeinatedContentStorage {

    func sizeThatFits(
        proposal: SizeConstraint,
        environment: Environment,
        node: LayoutTreeNode,
        cache: CrossLayoutSizeCache?
    ) -> CGSize {
        measurer(proposal, environment)
    }

    func performCaffeinatedLayout(
        frame: CGRect,
        environment: Environment,
        node: LayoutTreeNode
    ) -> [IdentifiedNode] {
        []
    }
}
