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
}

extension CacheTree {
    /// Convenience method to get a cached size, or compute and store one if it is not in the cache.
    func get(_ constraint: SizeConstraint, orStore calculation: (SizeConstraint) -> CGSize) -> CGSize {

        if let size = self[constraint] {
            return size
        } else {
            let size = calculation(constraint)

            self[constraint] = size

            return size
        }
    }

    /// Gets a subcache for an element with siblings.
    func subcache(index: Int, of childCount: Int, element: Element) -> CacheTree {
        subcache(
            key: index,
            name: childCount == 1
                ? "\(name).\(type(of: element))"
                : "\(name)[\(index)].\(type(of: element))"
        )
    }

    /// Gets a subcache for an element with no siblings.
    func subcache(element: Element) -> CacheTree {
        subcache(index: 0, of: 1, element: element)
    }
}
