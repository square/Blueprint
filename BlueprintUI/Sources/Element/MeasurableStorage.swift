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
        let key = MeasurableSizeKey(model: cacheKey, max: proposal.maximum)
        return environment.cacheStorage.measurableStorageCache.retrieveOrCreate(
            key: key,
            environment: environment,
            context: .internalElementLayout
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
        let hashValue: Int
        init(model: AnyHashable, max: CGSize) {
            var hasher = Hasher()
            model.hash(into: &hasher)
            max.hash(into: &hasher)
            hashValue = hasher.finalize()
        }
    }

}

extension CacheStorage {

    private struct MeasurableStorageCacheKey: CacheKey {
        static var emptyValue = EnvironmentEntangledCache<MeasurableStorage.MeasurableSizeKey, CGSize>()
    }

    fileprivate var measurableStorageCache: EnvironmentEntangledCache<MeasurableStorage.MeasurableSizeKey, CGSize> {
        get { self[MeasurableStorageCacheKey.self] }
        set { self[MeasurableStorageCacheKey.self] = newValue }
    }

}
