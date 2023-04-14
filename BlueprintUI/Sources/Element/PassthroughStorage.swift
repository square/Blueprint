import Foundation

/// A storage type that simply delegates its measurement and layout to
/// another child, without any modification.
struct PassthroughStorage: ContentStorage {

    typealias IdentifiedNode = ElementContent.IdentifiedNode

    let childCount = 1

    var child: Element
    var content: ElementContent
    var identifier: ElementIdentifier

    init(child: Element) {
        self.child = child
        content = child.content
        identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)
    }
}

extension PassthroughStorage: LegacyContentStorage {

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

        let childAttributes = LayoutAttributes(size: attributes.bounds.size)

        let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)

        let node = LayoutResultNode(
            element: child,
            layoutAttributes: childAttributes,
            environment: environment,
            children: child.content.performLegacyLayout(
                attributes: childAttributes,
                environment: environment,
                cache: cache.subcache(element: child)
            )
        )

        return [(identifier, node)]
    }
}

extension PassthroughStorage: CaffeinatedContentStorage {

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

    func performCaffeinatedLayout(
        frame: CGRect,
        environment: Environment,
        node: LayoutTreeNode
    ) -> [IdentifiedNode] {
        let childAttributes = LayoutAttributes(size: frame.size)
        let subnode = node.subnode(key: identifier)

        let node = LayoutResultNode(
            element: child,
            layoutAttributes: childAttributes,
            environment: environment,
            children: content.performCaffeinatedLayout(
                frame: frame,
                environment: environment,
                node: subnode
            )
        )

        return [(identifier, node)]
    }

}
