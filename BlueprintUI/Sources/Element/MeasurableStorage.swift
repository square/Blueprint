import CoreGraphics

/// Content storage for leaf nodes.
struct MeasurableStorage: ContentStorage {

    typealias IdentifiedNode = ElementContent.IdentifiedNode

    let childCount = 0

    let cacheKey: AnyHashable?
    let measurer: (SizeConstraint, Environment) -> CGSize
}

extension MeasurableStorage: CaffeinatedContentStorage {

    func sizeThatFits(
        proposal: SizeConstraint,
        environment: Environment,
        node: LayoutTreeNode
    ) -> CGSize {
        guard environment.layoutMode.options.measureableStorageCache, let cacheKey else {
            return measurer(proposal, environment)
        }

        let key = MeasurableSizeKey(path: node.path, max: proposal.maximum)
        return environment.cacheStorage.measurableStorageCache.retrieveOrCreate(
            key: key,
            environment: environment,
            context: .elementSizing,
            validationValue: cacheKey
        ) {
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
        static var emptyValue = ValidatingCache<MeasurableStorage.MeasurableSizeKey, CGSize, EnvironmentEntangled>()
    }

    fileprivate var measurableStorageCache: ValidatingCache<
        MeasurableStorage.MeasurableSizeKey,
        CGSize,
        EnvironmentEntangled
    > {
        get { self[MeasurableStorageCacheKey.self] }
        set { self[MeasurableStorageCacheKey.self] = newValue }
    }

}
