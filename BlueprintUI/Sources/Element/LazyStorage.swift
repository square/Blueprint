import CoreGraphics

/// Content storage that defers creation of its child until measurement or layout time.
struct LazyStorage: ContentStorage {

    typealias IdentifiedNode = ElementContent.IdentifiedNode

    let childCount = 1

    var builder: (ElementContent.LayoutPhase, SizeConstraint, Environment) -> Element

    private func buildChild(
        for phase: ElementContent.LayoutPhase,
        in constraint: SizeConstraint,
        environment: Environment
    ) -> Element {
        builder(phase, constraint, environment)
    }
}

extension LazyStorage: LegacyContentStorage {

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
            identifier: identifier,
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
}

extension LazyStorage: CaffeinatedContentStorage {

    func sizeThatFits(
        proposal: SizeConstraint,
        environment: Environment,
        node: LayoutTreeNode
    ) -> CGSize {
        let child = buildChild(
            for: .measurement,
            in: proposal,
            environment: environment
        )
        let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)
        let subnode = node.subnode(key: identifier)

        return child.content.sizeThatFits(
            proposal: proposal,
            environment: environment,
            node: subnode
        )
    }

    func performCaffeinatedLayout(
        frame: CGRect,
        environment: Environment,
        node: LayoutTreeNode
    ) -> [IdentifiedNode] {
        let child = buildChild(
            for: .layout,
            in: SizeConstraint(frame.size),
            environment: environment
        )

        let childAttributes = LayoutAttributes(size: frame.size)
        let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)
        let subnode = node.subnode(key: identifier)

        let node = LayoutResultNode(
            identifier: identifier,
            element: child,
            layoutAttributes: childAttributes,
            environment: environment,
            children: child.content.performCaffeinatedLayout(
                frame: frame,
                environment: environment,
                node: subnode
            )
        )

        return [(identifier, node)]
    }

}

extension LazyStorage: CaffeinatedContentStorageCrossRenderCached {

    func sizeThatFitsWithCache(
        proposal: SizeConstraint,
        with environment: Environment,
        state: ElementState
    ) -> CGSize {
        state.sizeThatFits(proposal: proposal, with: environment) { environment in

            let child = buildChild(for: .measurement, in: proposal, environment: environment)
            let identifier = ElementIdentifier.identifierFor(singleChild: child)
            let childState = state.childState(for: child, in: environment, with: identifier)

            return childState.elementContent.sizeThatFitsWithCache(
                proposal: proposal,
                with: environment,
                state: childState
            )
        }
    }

    func performCachedCaffeinatedLayout(in size: CGSize, with environment: Environment, state: ElementState) -> [LayoutResultNode] {
        state.layout(in: size, with: environment) { environment in
            let constraint = SizeConstraint(size)
            let child = buildChild(for: .layout, in: constraint, environment: environment)

            let childAttributes = LayoutAttributes(size: size)

            let identifier = ElementIdentifier.identifierFor(singleChild: child)

            let childState = state.childState(for: child, in: environment, with: identifier)

            let node = LayoutResultNode(
                identifier: identifier,
                element: childState.element.latest,
                layoutAttributes: childAttributes,
                environment: environment,
                children: childState.elementContent.performCachedCaffeinatedLayout(
                    in: size,
                    with: environment,
                    state: childState
                ).caffeinatedBridgedWithIdentity
            )

            return [node]
        }
    }

    func forEachElement(
        in size: CGSize,
        with environment: Environment,
        children childNodes: [LayoutResultNode],
        state: ElementState,
        forEach: (ElementContent.ForEachElementContext) -> Void
    ) {
        precondition(childNodes.count == 1)

        let element = builder(.layout, SizeConstraint(size), environment)

        let childState = state.childState(for: element, in: environment, with: .identifierFor(singleChild: element))

        let childNode = childNodes[0]

        forEach(.init(state: childState, element: element, layoutNode: childNode))

        childState.elementContent.forEachElement(
            with: childNode,
            environment: environment,
            state: childState,
            forEach: forEach
        )
    }

}
