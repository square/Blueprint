import CoreGraphics

/// A cache implementation suitable for the lifetime of a single render pass or measurement.
final class RenderPassCache: CacheTree {

    let name: String
    let signpostRef: AnyObject

    private var subcaches: [SubcacheKey: RenderPassCache] = [:]
    private var measurements: [SizeConstraint: CGSize] = [:]

    var content: ElementContent

    init(name: String, content: ElementContent, signpostRef: AnyObject) {
        self.name = name
        self.signpostRef = signpostRef
        self.content = content
    }

    subscript(constraint: SizeConstraint) -> CGSize? {
        get {
            measurements[constraint]
        }
        set {
            measurements[constraint] = newValue
        }
    }

    func subcache(key: SubcacheKey, content: () -> ElementContent, name: @autoclosure () -> String) -> CacheTree {
        if let subcache = subcaches[key] {
            return subcache
        }

        let subcache = RenderPassCache(name: name(), content: content(), signpostRef: signpostRef)
        subcaches[key] = subcache
        return subcache
    }
}
