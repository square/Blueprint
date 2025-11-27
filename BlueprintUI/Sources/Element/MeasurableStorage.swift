import CoreGraphics

/// Content storage for leaf nodes.
struct MeasurableStorage: ContentStorage {

    typealias IdentifiedNode = ElementContent.IdentifiedNode

    let childCount = 0

    let validationKey: AnyCrossLayoutCacheable?
    let measurer: (SizeConstraint, Environment) -> CGSize

    init(validationKey: some CrossLayoutCacheable, measurer: @escaping (SizeConstraint, Environment) -> CGSize) {
        self.validationKey = AnyCrossLayoutCacheable(validationKey)
        self.measurer = measurer
    }

    init(measurer: @escaping (SizeConstraint, Environment) -> CGSize) {
        validationKey = nil
        self.measurer = measurer
    }
}

extension MeasurableStorage: CaffeinatedContentStorage {

    func sizeThatFits(
        proposal: SizeConstraint,
        environment: Environment,
        node: LayoutTreeNode
    ) -> CGSize {
        guard environment.layoutMode.options.measureableStorageCache, let validationKey else {
            return measurer(proposal, environment)
        }

        let key = MeasurableSizeKey(path: node.path, max: proposal.maximum)
        return environment.hostingViewContext.measurableStorageCache.retrieveOrCreate(
            key: key,
            environment: environment,
            validationValue: validationKey,
            context: .elementSizing,
        ) { environment in
            measurer(proposal, environment)
        }
    }

    func performCaffeinatedLayout(
        frame: CGRect,
        environment: Environment,
        node: LayoutTreeNode
    ) -> [IdentifiedNode] {
        []
    }
}

extension MeasurableStorage {

    fileprivate struct MeasurableSizeKey: Hashable {

        let path: String
        let max: CGSize

        func hash(into hasher: inout Hasher) {
            path.hash(into: &hasher)
            max.hash(into: &hasher)
        }

    }

}

extension HostingViewContext {

    private struct MeasurableStorageCacheKey: CrossLayoutCacheKey {
        static var emptyValue = EnvironmentAndValueValidatingCache<
            MeasurableStorage.MeasurableSizeKey,
            CGSize,
            AnyCrossLayoutCacheable
        >()
    }

    fileprivate var measurableStorageCache: EnvironmentAndValueValidatingCache<
        MeasurableStorage.MeasurableSizeKey,
        CGSize,
        AnyCrossLayoutCacheable
    > {
        get { self[MeasurableStorageCacheKey.self] }
        set { self[MeasurableStorageCacheKey.self] = newValue }
    }

}
