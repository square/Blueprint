import CoreGraphics

protocol CacheProvider: AnyObject {
    var cache: [AnyHashable: Any] { get set }
}

/// Content storage for leaf nodes.
struct CachedMeasurableStorage<CacheType>: ContentStorage {

    typealias IdentifiedNode = ElementContent.IdentifiedNode

    let childCount = 0

    let measurer: (SizeConstraint, Environment, inout CacheType?) -> CGSize
    weak var cacheProvider: CacheProvider?
}

extension CachedMeasurableStorage: CaffeinatedContentStorage {

    func sizeThatFits(
        proposal: SizeConstraint,
        environment: Environment,
        node: LayoutTreeNode
    ) -> CGSize {
        var cache: CacheType? = nil
        return measurer(proposal, environment, &cache)
    }

    func performCaffeinatedLayout(
        frame: CGRect,
        environment: Environment,
        node: LayoutTreeNode
    ) -> [IdentifiedNode] {
        []
    }
}
