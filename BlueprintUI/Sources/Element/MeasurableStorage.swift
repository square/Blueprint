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
        node: LayoutTreeNode
    ) -> CGSize {
        if let cached = cachedValue(proposal: proposal, environment: environment, node: node) {
            return cached
        }
        return measurer(proposal, environment)
    }

    func performCaffeinatedLayout(
        frame: CGRect,
        environment: Environment,
        node: LayoutTreeNode
    ) -> [IdentifiedNode] {
        []
    }
}

extension MeasurableStorage {

    private static var cache: [ElementIdentifier: CGSize] = [:]

//    struct CacheKey: Hashable {
//        let elementIdentifier: ElementIdentifier
//        let environment: Environment
//        let node: LayoutTreeNode
//    }

    func cachedValue(
        proposal: SizeConstraint,
        environment: Environment,
        node: LayoutTreeNode
    ) -> CGSize? {
        nil
    }

}
