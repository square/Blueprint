import CoreGraphics
import os.log

/// A size cache that also holds subcaches.
protocol CacheTree: AnyObject {

    typealias SubcacheKey = Int

    /// The name of this cache
    var name: String { get }

    /// A reference to use for logging
    var signpostRef: AnyObject { get }

    /// The sizes that are contained in this cache, keyed by size constraint.
    subscript(constraint: SizeConstraint) -> CGSize? { get set }

    /// Gets a subcache identified by the given key, or creates a new one.
    func subcache(key: SubcacheKey, name: @autoclosure () -> String) -> CacheTree
    
    func outOfBandCache(key: AnyHashable) -> CacheTree
}

extension CacheTree {
    /// Convenience method to get a cached size, or compute and store one if it is not in the cache.
    func get(_ constraint: SizeConstraint, orStore calculation: (SizeConstraint) -> CGSize) -> CGSize {

//        print("measure \(name)")
//        if (name == "Row/Column.0/Spacer.0") {
//            print("xxx")
//        }
        if let size = self[constraint] {
            Logger.logCacheHit(object: self.signpostRef, description: name, constraint: constraint)
            return size
        } else {
            Logger.logCacheMiss(object: signpostRef, description: name, constraint: constraint)
            
            Logger.logMeasureStart(
                object: signpostRef,
                description: name,
                constraint: constraint
            )

            let size = calculation(constraint)

            Logger.logMeasureEnd(object: signpostRef)

            self[constraint] = size

            return size
        }
    }

    /// Gets a subcache for an element with siblings.
    func subcache(index: Int, of childCount: Int, element: Element) -> CacheTree {
        subcache(
            key: index,
            name: "\(name)/\(type(of: element)).\(index)"
        )
    }

    /// Gets a subcache for an element with no siblings.
    func subcache(element: Element) -> CacheTree {
        subcache(index: 0, of: 1, element: element)
    }
}
