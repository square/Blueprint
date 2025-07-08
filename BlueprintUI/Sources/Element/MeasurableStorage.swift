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
        let key = CacheStorage.SizeKey(model: cacheKey, max: proposal.maximum)
        if let (cached, cachedEnv) = environment.cacheStorage.measurableStorageCache[key] {
            if cachedEnv.isEquivalent(to: environment, in: .internalElementLayout) {
                #if DEBUG
                print("Cached size")
                #endif
                return cached
            } else {
                environment.cacheStorage.measurableStorageCache.removeValue(forKey: key)
            }
        }
        let measured = measurer(proposal, environment)
        environment.cacheStorage.measurableStorageCache[key] = (measured, environment)
        return measured
    }

    func performCaffeinatedLayout(
        frame: CGRect,
        environment: Environment,
        node: LayoutTreeNode
    ) -> [IdentifiedNode] {
        []
    }
}

extension CacheStorage {

    private struct MeasurableStorageCacheKey: Key {
        static var emptyValue: [SizeKey: (CGSize, Environment)] = [:]
    }

    fileprivate var measurableStorageCache: [SizeKey: (CGSize, Environment)] {
        get { self[MeasurableStorageCacheKey.self] }
        set { self[MeasurableStorageCacheKey.self] = newValue }
    }

    fileprivate struct SizeKey: Hashable {
        let hashValue: Int
        init(model: AnyHashable, max: CGSize) {
            var hasher = Hasher()
            model.hash(into: &hasher)
            max.hash(into: &hasher)
            hashValue = hasher.finalize()
        }

    }

}
