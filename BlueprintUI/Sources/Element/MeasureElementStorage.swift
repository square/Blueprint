import Foundation

struct MeasureElementStorage: ContentStorage {

    typealias IdentifiedNode = ElementContent.IdentifiedNode

    let childCount = 0

    var child: Element
    var content: ElementContent
    var identifier: ElementIdentifier

    init(child: Element) {
        self.child = child
        content = child.content
        identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)
    }
}

extension MeasureElementStorage: LegacyContentStorage {

    func measure(
        in constraint: SizeConstraint,
        environment: Environment,
        cache: CacheTree
    ) -> CGSize {
        cache.get(constraint) { constraint -> CGSize in

            Logger.logMeasureStart(
                object: cache.signpostRef,
                description: cache.name,
                constraint: constraint
            )

            defer { Logger.logMeasureEnd(object: cache.signpostRef) }

            return child.content.measure(
                in: constraint,
                environment: environment,
                cache: cache.subcache(element: child)
            )
        }
    }

    func performLegacyLayout(
        attributes: LayoutAttributes,
        environment: Environment,
        cache: CacheTree
    ) -> [IdentifiedNode] {
        []
    }
}

extension MeasureElementStorage: CaffeinatedContentStorage {

    func sizeThatFits(
        proposal: SizeConstraint,
        environment: Environment,
        node: LayoutTreeNode
    ) -> CGSize {
        content.sizeThatFits(
            proposal: proposal,
            environment: environment,
            node: node.subnode(key: identifier)
        )
    }

    func performCaffeinatedLayout(frame: CGRect, environment: Environment, node: LayoutTreeNode) -> [ElementContent.IdentifiedNode] {
        []
    }

}

extension MeasureElementStorage: CaffeinatedContentStorageCrossRenderCached {

    func cachedMeasure(in constraint: SizeConstraint, with environment: Environment, state: ElementState) -> CGSize {
        content.cachedMeasure(in: constraint, with: environment, state: state)
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
        content.forEachElement(in: size, with: environment, children: childNodes, state: state, forEach: forEach)
    }

}
