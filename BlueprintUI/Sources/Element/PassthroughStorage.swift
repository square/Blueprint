import Foundation

/// A storage type that simply delegates its measurement and layout to
/// another child, without any modification.
struct PassthroughStorage: ContentStorage {

    let childCount: Int = 1

    var child: Element

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

    func performLayout(
        attributes: LayoutAttributes,
        environment: Environment,
        cache: CacheTree
    ) -> [(identifier: ElementIdentifier, node: LayoutResultNode)] {

        let childAttributes = LayoutAttributes(size: attributes.bounds.size)

        let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)

        let node = LayoutResultNode(
            element: child,
            layoutAttributes: childAttributes,
            environment: environment,
            children: child.content.performLayout(
                attributes: childAttributes,
                environment: environment,
                cache: cache.subcache(element: child)
            )
        )

        return [(identifier, node)]
    }
}
