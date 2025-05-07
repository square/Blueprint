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
    var identifier: ElementIdentifier

    init(adapter: @escaping (inout Environment) -> Void, child: Element) {
        self.adapter = adapter
        self.child = child
        content = child.content
        identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)
    }

    private func adapted(environment: Environment) -> Environment {
        var environment = environment
        adapter(&environment)
        return environment
    }
}

extension EnvironmentAdaptingStorage: LegacyContentStorage {

    func performLegacyLayout(
        attributes: LayoutAttributes,
        environment: Environment,
        cache: CacheTree
    ) -> [IdentifiedNode] {
        let environment = adapted(environment: environment)

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

            let environment = adapted(environment: environment)

            return child.content.measure(
                in: constraint,
                environment: environment,
                cache: cache.subcache(element: child)
            )
        }
    }
}

extension EnvironmentAdaptingStorage: CaffeinatedContentStorage {

    func sizeThatFits(
        proposal: SizeConstraint,
        environment: Environment,
        node: LayoutTreeNode
    ) -> CGSize {
        let environment = adapted(environment: environment)
        let subnode = node.subnode(key: identifier)
        return content.sizeThatFits(proposal: proposal, environment: environment, node: subnode)
    }

    func performCaffeinatedLayout(
        frame: CGRect,
        environment: Environment,
        node: LayoutTreeNode
    ) -> [IdentifiedNode] {
        let environment = adapted(environment: environment)
        let childAttributes = LayoutAttributes(size: frame.size)
        let subnode = node.subnode(key: identifier)

        let node = LayoutResultNode(
            identifier: .identifierFor(singleChild: child),
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

extension EnvironmentAdaptingStorage: CaffeinatedContentStorageCrossRenderCached {

    func cachedMeasure(in constraint: SizeConstraint, with environment: Environment, state: ElementState) -> CGSize {
        state.measure(in: constraint, with: environment) { environment in

            let environment = self.adapted(environment: environment)
            let identifier = ElementIdentifier.identifierFor(singleChild: child)
            let childState = state.childState(for: child, in: environment, with: identifier)

            return childState.elementContent.cachedMeasure(
                in: constraint,
                with: environment,
                state: childState
            )
        }
    }

    func performCachedCaffeinatedLayout(in size: CGSize, with environment: Environment, state: ElementState) -> [LayoutResultNode] {
        state.layout(in: size, with: environment) { environment in
            let environment = adapted(environment: environment)
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

        var environment = environment
        adapter(&environment)

        let childState = state.childState(for: child, in: environment, with: .identifierFor(singleChild: child))

        let childNode = childNodes[0]

        forEach(.init(state: childState, element: child, layoutNode: childNode))

        childState.elementContent.forEachElement(
            with: childNode,
            environment: environment,
            state: childState,
            forEach: forEach
        )
    }
}
