import CoreGraphics

/// Content storage that applies a change to the environment.
struct EnvironmentAdaptingStorage: ContentStorage {

    typealias IdentifiedNode = ElementContent.IdentifiedNode

    let childCount = 1

    /// During measurement or layout, the environment adapter will be applied
    /// to the environment before passing it
    ///
    var adapter: (inout Environment) -> Void

    var child: Element
    var content: ElementContent

    init(adapter: @escaping (inout Environment) -> Void, child: Element) {
        self.adapter = adapter
        self.child = child
        content = child.content
    }

    func performLegacyLayout(
        attributes: LayoutAttributes,
        environment: Environment,
        cache: CacheTree
    ) -> [IdentifiedNode] {
        let environment = adapted(environment: environment)

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

            let environment = adapted(environment: environment)

            return child.content.measure(
                in: constraint,
                environment: environment,
                cache: cache.subcache(element: child)
            )
        }
    }

    func sizeThatFits(proposal: SizeConstraint, context: MeasureContext) -> CGSize {
        let environment = adapted(environment: context.environment)
        let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)
        let context = MeasureContext(
            environment: environment,
            node: context.node.subnode(key: identifier)
        )
        return child.content.sizeThatFits(proposal: proposal, context: context)
    }

    func performCaffeinatedLayout(
        frame: CGRect,
        context: LayoutContext
    ) -> [IdentifiedNode] {
        let environment = adapted(environment: context.environment)

        let childAttributes = LayoutAttributes(size: frame.size)

        let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)

        let context = LayoutContext(
            environment: environment,
            node: context.node.subnode(key: identifier)
        )

        let node = LayoutResultNode(
            element: child,
            layoutAttributes: childAttributes,
            environment: environment,
            children: content.performCaffeinatedLayout(
                frame: frame,
                context: context
            )
        )

        return [(identifier, node)]
    }

    private func adapted(environment: Environment) -> Environment {
        var environment = environment
        adapter(&environment)
        return environment
    }
}
