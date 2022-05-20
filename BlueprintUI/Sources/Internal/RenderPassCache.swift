import CoreGraphics

/// A cache implementation suitable for the lifetime of a single render pass or measurement.
final class RenderPassCache: CacheTree {

    let name: String
    let signpostRef: AnyObject
    let screenScale: CGFloat

    private var subcaches: [SubcacheKey: RenderPassCache] = [:]
    private var measurements: [SizeConstraint: CGSize] = [:]

    init(name: String, signpostRef: AnyObject, screenScale: CGFloat) {
        self.name = name
        self.signpostRef = signpostRef
        self.screenScale = screenScale
    }

    subscript(constraint: SizeConstraint) -> CGSize? {
        get {
            measurements[constraint]
        }
        set {
            measurements[constraint] = newValue
        }
    }

    func subcache(key: SubcacheKey, name: @autoclosure () -> String) -> CacheTree {
        if let subcache = subcaches[key] {
            return subcache
        }

        let subcache = RenderPassCache(name: name(), signpostRef: signpostRef, screenScale: screenScale)
        subcaches[key] = subcache
        return subcache
    }
}
