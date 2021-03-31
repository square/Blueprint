import CoreGraphics
import os.log

/// A size cache that also holds subcaches.
protocol CacheTree: AnyObject {

    /// The name of this cache
    var name: String { get }

    /// A reference to use for logging
    var signpostRef: AnyObject { get }

    /// The sizes that are contained in this cache, keyed by size constraint.
    subscript(constraint: SizeConstraint) -> CGSize? { get set }

    /// Gets a subcache identified by the given key, or creates a new one.
    func subcache(key: SubcacheKey, name: @autoclosure () -> String) -> CacheTree
}

struct SubcacheKey: RawRepresentable, Hashable {
    /// A key indicating that this will be the only subcache
    static let singleton = SubcacheKey(rawValue: -1)

    let rawValue: Int
}

extension CacheTree {
    /// Convenience method to get a cached size, or compute and store one if it is not in the cache.
    func get(_ constraint: SizeConstraint, orStore calculation: (SizeConstraint) -> CGSize) -> CGSize {
        if let size = self[constraint] {
            return size
        }
        let size = calculation(constraint)
        self[constraint] = size
        return size
    }

    /// Gets a subcache for an element with siblings.
    func subcache(index: Int, element: Element) -> CacheTree {
        subcache(key: SubcacheKey(rawValue: index), element: element)
    }

    /// Gets a subcache for an element.
    func subcache(key: SubcacheKey = .singleton, element: Element) -> CacheTree {
        subcache(
            key: key,
            name: key == .singleton
                ? "\(self.name).\(type(of: element))"
                : "\(self.name)[\(key.rawValue)].\(type(of: element))"
        )
    }
}
