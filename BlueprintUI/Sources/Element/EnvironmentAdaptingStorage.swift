import CoreGraphics

/// Content storage that applies a change to the environment.
struct EnvironmentAdaptingStorage: ContentStorage {
    let childCount = 1

    /// During measurement or layout, the environment adapter will be applied
    /// to the environment before passing it
    ///
    var adapter: (inout Environment) -> Void

    var child: Element

    func performLegacyLayout(
        attributes: LayoutAttributes,
        environment: Environment,
        cache: CacheTree
    ) -> [(identifier: ElementIdentifier, node: LayoutResultNode)] {
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

    private func adapted(environment: Environment) -> Environment {
        var environment = environment
        adapter(&environment)
        return environment
    }
}
