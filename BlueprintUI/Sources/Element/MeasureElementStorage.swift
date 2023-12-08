import Foundation

struct MeasureElementStorage: ContentStorage {

    typealias IdentifiedNode = ElementContent.IdentifiedNode

    let childCount = 0

    var child: Element
    var content: ElementContent
    var identifier: ElementIdentifier

    let axes: ElementContent.MeasuringAxes

    init(child: Element, axes: ElementContent.MeasuringAxes) {
        self.child = child
        self.axes = axes

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

            return size(
                with: child.content.measure(
                    in: constraint,
                    environment: environment,
                    cache: cache.subcache(element: child)
                )
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

    fileprivate func size(with size: CGSize) -> CGSize {
        switch axes {
        case .horizontal:
            return CGSize(width: size.width, height: 0)
        case .vertical:
            return CGSize(width: 0, height: size.height)
        case .both:
            return size
        }
    }
}

extension MeasureElementStorage: CaffeinatedContentStorage {

    func sizeThatFits(
        proposal: SizeConstraint,
        environment: Environment,
        node: LayoutTreeNode
    ) -> CGSize {
        size(
            with: content.sizeThatFits(
                proposal: proposal,
                environment: environment,
                node: node.subnode(key: identifier)
            )
        )
    }

    func performCaffeinatedLayout(
        frame: CGRect,
        environment: Environment,
        node: LayoutTreeNode
    ) -> [IdentifiedNode] {
        []
    }
}
