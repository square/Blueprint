import CoreGraphics
import Foundation


final class SPCacheTree<Key, Value, SubcacheKey> where Key: Hashable, SubcacheKey: Hashable {

    typealias Subcache = SPCacheTree<Key, Value, SubcacheKey>

    var valueCache: SPValueCache<Key, Value>
    private var subcaches: [SubcacheKey: Subcache] = [:]

    var path: String

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
    
    var layoutSubviews: [LayoutSubview]?
    
    // TODO: generalize hanging anything off this cache
    func layoutSubviews(create: () -> [LayoutSubview]) -> [LayoutSubview] {
        if let layoutSubviews = layoutSubviews {
            return layoutSubviews
        }
        let layoutSubviews = create()
        self.layoutSubviews = layoutSubviews
        return layoutSubviews
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
