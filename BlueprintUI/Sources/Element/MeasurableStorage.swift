import CoreGraphics

/// Content storage for leaf nodes.
struct MeasurableStorage: ContentStorage, CaffeinatedContentStorage {

    typealias IdentifiedNode = ElementContent.IdentifiedNode

    let childCount = 0

    let measurer: (SizeConstraint, Environment) -> CGSize

    func sizeThatFits(
        proposal: SizeConstraint,
        environment: Environment,
        node: LayoutTreeNode
    ) -> CGSize {
        measurer(proposal, environment)
    }

    func performCaffeinatedLayout(
        frame: CGRect,
        environment: Environment,
        node: LayoutTreeNode
    ) -> [IdentifiedNode] {
        []
    }
}


/// Content storage for leaf nodes, but allows caching storage.
struct CachingMeasurableStorage: ContentStorage, CaffeinatedContentStorage {

    typealias IdentifiedNode = ElementContent.IdentifiedNode

    let childCount = 0

    let cacheValue: any Equatable

    let measurer: (SizeConstraint, Environment) -> CGSize

    func sizeThatFits(
        proposal: SizeConstraint,
        environment: Environment,
        node: LayoutTreeNode
    ) -> CGSize {
        measurer(
            proposal,
            environment
                .adapted(key: CacheAccessKey.self, value: node.state)
        )
    }

    func performCaffeinatedLayout(
        frame: CGRect,
        environment: Environment,
        node: LayoutTreeNode
    ) -> [IdentifiedNode] {
        []
    }

    private enum CacheAccessKey: EnvironmentKey {

        static func isEquivalent(_ lhs: ElementState, _ rhs: ElementState) -> Bool {
            // TODO: Uhh I think this is fine since this is just an accessor type?
            true
        }

        static var defaultValue: ElementState {
            fatalError()
        }
    }
}
