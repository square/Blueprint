import CoreGraphics

/// Content storage that defers creation of its child until measurement or layout time.
struct LazyStorage: ContentStorage {

    typealias IdentifiedNode = ElementContent.IdentifiedNode

    let childCount = 1

    var builder: (ElementContent.LayoutPhase, SizeConstraint, Environment) -> Element

    func performLegacyLayout(
        attributes: LayoutAttributes,
        environment: Environment,
        cache: CacheTree
    ) -> [IdentifiedNode] {
        let constraint = SizeConstraint(attributes.bounds.size)
        let child = buildChild(for: .layout, in: constraint, environment: environment)
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

    func measure(in constraint: SizeConstraint, environment: Environment, cache: CacheTree) -> CGSize {
        cache.get(constraint) { constraint -> CGSize in
            Logger.logMeasureStart(
                object: cache.signpostRef,
                description: cache.name,
                constraint: constraint
            )

            defer { Logger.logMeasureEnd(object: cache.signpostRef) }

            let child = buildChild(for: .measurement, in: constraint, environment: environment)

            return child.content.measure(
                in: constraint,
                environment: environment,
                cache: cache.subcache(element: child)
            )
        }
    }

    func sizeThatFits(proposal: SizeConstraint, context: MeasureContext) -> CGSize {
        let child = buildChild(
            for: .measurement,
            in: proposal,
            environment: context.environment
        )
        let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)
        let context = MeasureContext(
            environment: context.environment,
            node: context.node.subnode(key: identifier)
        )
        return child.content.sizeThatFits(proposal: proposal, context: context)
    }

    func performCaffeinatedLayout(
        frame: CGRect,
        context: LayoutContext
    ) -> [IdentifiedNode] {
        let child = buildChild(
            for: .layout,
            in: SizeConstraint(frame.size),
            environment: context.environment
        )

        let childAttributes = LayoutAttributes(size: frame.size)

        let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)

        let context = LayoutContext(
            environment: context.environment,
            node: context.node.subnode(key: identifier)
        )

        let node = LayoutResultNode(
            element: child,
            layoutAttributes: childAttributes,
            environment: context.environment,
            children: child.content.performCaffeinatedLayout(
                frame: frame,
                context: context
            )
        )

        return [(identifier, node)]
    }


    private func buildChild(
        for phase: ElementContent.LayoutPhase,
        in constraint: SizeConstraint,
        environment: Environment
    ) -> Element {
        builder(phase, constraint, environment)
    }
}
