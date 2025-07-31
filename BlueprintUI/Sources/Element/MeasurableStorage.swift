import CoreGraphics

/// Content storage for leaf nodes.
struct MeasurableStorage: ContentStorage, CaffeinatedContentStorage {

    typealias IdentifiedNode = ElementContent.IdentifiedNode

    let childCount = 0

    let measurer: (SizeConstraint, Environment) -> CGSize

    func sizeThatFits(
        proposal: SizeConstraint,
        environment: Environment,
        node: LayoutTreeNode
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


/// Content storage for leaf nodes, but allows caching storage.
struct CachingMeasurableStorage: ContentStorage, CaffeinatedContentStorage {

    typealias IdentifiedNode = ElementContent.IdentifiedNode

    let childCount = 0

    let cacheValue: any Equatable

    let measurer: (SizeConstraint, Environment) -> CGSize

    func sizeThatFits(
        proposal: SizeConstraint,
        environment: Environment,
        node: LayoutTreeNode
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
