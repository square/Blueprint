import CoreGraphics

/// Content storage for leaf nodes.
struct MeasurableStorage: ContentStorage {

    typealias IdentifiedNode = ElementContent.IdentifiedNode

    let childCount = 0

    let measurer: (SizeConstraint, Environment) -> CGSize
}

extension MeasurableStorage: LegacyContentStorage {

    func performLegacyLayout(
        attributes: LayoutAttributes,
        environment: Environment,
        cache: CacheTree
    ) -> [IdentifiedNode] {
        []
    }

    func measure(in constraint: SizeConstraint, environment: Environment, cache: CacheTree) -> CGSize {
        cache.get(constraint) { constraint in
            Logger.logMeasureStart(
                object: cache.signpostRef,
                description: cache.name,
                constraint: constraint
            )

            defer { Logger.logMeasureEnd(object: cache.signpostRef) }

            return measurer(constraint, environment)
        }
    }
}

extension MeasurableStorage: CaffeinatedContentStorage {

    func sizeThatFits(
        proposal: SizeConstraint,
        environment: Environment,
        node: LayoutTreeNode
    ) -> CGSize {
        measurer(proposal, environment)
    }

    func performCaffeinatedLayout(frame: CGRect, environment: Environment, node: LayoutTreeNode) -> [ElementContent.IdentifiedNode] {
        []
    }

}

extension MeasurableStorage: CaffeinatedContentStorageCrossRenderCached {

    func sizeThatFitsWithCache(
        proposal: SizeConstraint,
        with environment: Environment,
        state: ElementState
    ) -> CGSize {
        state.sizeThatFits(proposal: proposal, with: environment) { environment in
            measurer(proposal, environment)
        }
    }

    func performCachedCaffeinatedLayout(in size: CGSize, with environment: Environment, state: ElementState) -> [LayoutResultNode] {
        []
    }

    func forEachElement(
        in size: CGSize,
        with environment: Environment,
        children childNodes: [LayoutResultNode],
        state: ElementState,
        forEach: (ElementContent.ForEachElementContext) -> Void
    ) {
        // No-op; we have no children.
    }
}
