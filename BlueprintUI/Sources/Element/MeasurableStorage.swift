import CoreGraphics

/// Content storage for leaf nodes.
struct MeasurableStorage: ContentStorage {

    typealias IdentifiedNode = ElementContent.IdentifiedNode

    let childCount = 0

    let validationKey: AnyContextuallyEquivalent?
    let measurer: (SizeConstraint, Environment) -> CGSize

    init(validationKey: some ContextuallyEquivalent, measurer: @escaping (SizeConstraint, Environment) -> CGSize) {
        self.validationKey = AnyContextuallyEquivalent(validationKey)
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
        return environment.cacheStorage.measurableStorageCache.retrieveOrCreate(
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

extension CacheStorage {

    private struct MeasurableStorageCacheKey: CacheKey {
        static var emptyValue = EnvironmentAndValueValidatingCache<
            MeasurableStorage.MeasurableSizeKey,
            CGSize,
            AnyContextuallyEquivalent
        >()
    }

    fileprivate var measurableStorageCache: EnvironmentAndValueValidatingCache<
        MeasurableStorage.MeasurableSizeKey,
        CGSize,
        AnyContextuallyEquivalent
    > {
        get { self[MeasurableStorageCacheKey.self] }
        set { self[MeasurableStorageCacheKey.self] = newValue }
    }

}
