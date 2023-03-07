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

            return content.measure(
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

    func sizeThatFits(proposal: SizeConstraint, context: MeasureContext) -> CGSize {
        content.sizeThatFits(
            proposal: proposal,
            context: MeasureContext(
                environment: context.environment,
                node: context.node.subnode(key: identifier)
            )
        )
    }

    func performCaffeinatedLayout(frame: CGRect, context: LayoutContext) -> [IdentifiedNode] {
        []
    }
}
