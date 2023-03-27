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

    func sizeThatFits(proposal: SizeConstraint, context: MeasureContext) -> CGSize {
        measurer(proposal, context.environment)
    }

    func performCaffeinatedLayout(
        frame: CGRect,
        context: LayoutContext
    ) -> [IdentifiedNode] {
        []
    }
}
