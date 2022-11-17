import CoreGraphics
import Foundation


final class SPCacheTree<Key, Value, SubcacheKey> where Key: Hashable, SubcacheKey: Hashable {

    typealias Subcache = SPCacheTree<Key, Value, SubcacheKey>

    var valueCache: SPValueCache<Key, Value>
    private var subcaches: [SubcacheKey: Subcache] = [:]

    var path: String

    private var layoutSubviews: [LayoutSubview]?

    private var _phaseCache: Any?

    init(path: String? = nil) {
        let path = path ?? ""
        self.path = path
        valueCache = .init(path: path)
    }

    func get(key: Key, or create: (Key) -> Value) -> Value {
        valueCache.get(key: key, or: create)
    }

    func subcache(key: SubcacheKey) -> Subcache {
        if let subcache = subcaches[key] {
            return subcache
        }
        let subcache = Subcache(path: path + "/" + String(describing: key))
        subcaches[key] = subcache
        return subcache
    }

    func layoutSubviews(create: () -> [LayoutSubview]) -> [LayoutSubview] {
        if let layoutSubviews = layoutSubviews {
            return layoutSubviews
        }
        let layoutSubviews = create()
        self.layoutSubviews = layoutSubviews
        return layoutSubviews
    }

    // TODO: Generalize using a EnvironmentKey system for better type safety?
    func phaseCache<PhaseCache>(create: () -> PhaseCache) -> PhaseCache {
        if let phaseCache = _phaseCache as? PhaseCache {
            return phaseCache
        }

        let phaseCache = create()
        _phaseCache = phaseCache
        return phaseCache
    }

    func `set`<PhaseCache>(phaseCache: PhaseCache) {
        _phaseCache = phaseCache
    }
}


final class SPValueCache<Key: Hashable, Value> {

    var values: [Key: Value] = [:]

    var path: String

    init(path: String) {
        self.path = path
    }

    func get(key: Key, or create: (Key) -> Value) -> Value {
        if let size = values[key] {
            return size
        }
        let size = create(key)
        values[key] = size
        return size
    }
}


typealias SPCacheNode = SPCacheTree<SizeConstraint, CGSize, SPCacheNodeKey>


struct SPCacheNodeKey: Hashable, CustomStringConvertible {
    var index: Int
    var isOOB: Bool = false

    var description: String {
        "\(index)\(isOOB ? ".oob" : "")"
    }
}


extension SPCacheTree where SubcacheKey == SPCacheNodeKey {

    func subcache(key: Int) -> Subcache {
        subcache(key: SPCacheNodeKey(index: key))
    }

    func oobSubcache(key: Int) -> Subcache {
        subcache(key: SPCacheNodeKey(index: key, isOOB: true))
    }
}
