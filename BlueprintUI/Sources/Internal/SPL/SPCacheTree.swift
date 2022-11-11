import CoreGraphics
import Foundation


final class SPCacheTree<Key, Value, SubcacheKey> where Key: Hashable, SubcacheKey: Hashable {

    typealias Subcache = SPCacheTree<Key, Value, SubcacheKey>

    var valueCache: SPValueCache<Key, Value>
    private var subcaches: [SubcacheKey: Subcache] = [:]

    var path: String

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


typealias SPCacheNode = SPCacheTree<SizeConstraint, CGSize, Int>
