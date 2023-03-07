import Foundation

struct MeasureElementStorage: ContentStorage {

    let child: Element

    let childCount: Int = 0

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
        []
    }
}
