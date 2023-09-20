import CoreGraphics
import Foundation

/// A node in the layout tree.
///
/// This tree is created during layout and measurement, and is used to hold information that may be
/// reused if a node is visited multiple times, such as measurement caches.
///
/// In the layout tree, each edge is keyed by an `ElementIdentifier`, and each node corresponds to
/// an `ElementContent`. An `ElementPath` can uniquely identify a node from the root. Elements that
/// lazily generate subelements, such as `GeometryReader`, may create subelements with distinct
/// identifiers across visits during a single render, which will result in extra nodes being created
/// that do not correspond to `LayoutResultNode` in the final layout. However, the
/// `LayoutResultNode` tree will be an isomorphic subgraph of this tree (every `LayoutResultNode`
/// corresponds to a `LayoutTreeNode`, but not every `LayoutTreeNode` produces a
/// `LayoutResultNode`).
///
final class LayoutTreeNode {

    typealias Subnode = LayoutTreeNode
    typealias SubnodeKey = ElementIdentifier

    private var subnodes: [SubnodeKey: Subnode] = [:]

    let path: String
    let sizeCache: HintingSizeCache

    // These commonly used properties have dedicated storage. If we need to hang more generalized
    // things off this type we may want to store them in a heterogeneous dictionary.
    private var _associatedCache: Any?

    init(path: String, signpostRef: AnyObject, options: LayoutOptions) {
        self.path = path
        sizeCache = HintingSizeCache(path: path, signpostRef: signpostRef, options: options)
    }

    func subnode(key: SubnodeKey) -> Subnode {
        if let subnode = subnodes[key] {
            return subnode
        }
        let subnode = Subnode(
            path: "\(path)/\(key)",
            signpostRef: sizeCache.signpostRef,
            options: sizeCache.options
        )
        subnodes[key] = subnode
        return subnode
    }

    func associatedCache<AssociatedCache>(create: () -> AssociatedCache) -> AssociatedCache {
        assert(
            _associatedCache is AssociatedCache?,
            "Expected associated cache of type \(AssociatedCache.self), not \(type(of: _associatedCache))"
        )
        if let associatedCache = _associatedCache as? AssociatedCache {
            return associatedCache
        }
        let associatedCache = create()
        _associatedCache = associatedCache
        return associatedCache
    }

    func update<AssociatedCache>(associatedCache: AssociatedCache) {
        _associatedCache = associatedCache
    }
}
