import CoreGraphics
import Foundation


final class SPCacheTree<Key, Value, SubcacheKey> where Key: Hashable, SubcacheKey: Hashable {
    
    typealias Subcache = SPCacheTree<Key, Value, SubcacheKey>
    
    var valueCache: SPValueCache<Key, Value>
    private var subcaches: [SubcacheKey: Subcache] = [:]
    
    var path: String
    
    private var layoutSubviews: [LayoutSubview]?
    
    private var _phaseCache: Any?
    
    init(path: String) {
        self.path = path
        valueCache = .init(path: path)
    }
    
    func subcache(key: SubcacheKey) -> Subcache {
        if let subcache = subcaches[key] {
            return subcache
        }
        let subcache = Subcache(path: "\(path)/\(key)")
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

extension SPCacheTree where Key == SizeConstraint {
    func get(key: Key, or create: (Key) -> Value) -> Value {
        valueCache.get(key: key, or: create)
    }
}

final class SPValueCache<Key: Hashable, Value> {
    
    var values: [Key: Value] = [:]
    
    var path: String
    
    init(path: String) {
        self.path = path
    }
}

extension SPValueCache where Key == SizeConstraint {

    func get(key: Key, or create: (Key) -> Value) -> Value {
        if let size = values[key] {
            Logger.logCacheHit(object: self, description: path, constraint: key)
            return size
        }
        
        Logger.logCacheMiss(object: self, description: path, constraint: key)
        
        Logger.logMeasureStart(object: self, description: path, constraint: key)
        let size = create(key)
        Logger.logMeasureEnd(object: self)

        values[key] = size
        return size
    }
}


typealias SPCacheNode = SPCacheTree<SizeConstraint, CGSize, ElementIdentifier>
