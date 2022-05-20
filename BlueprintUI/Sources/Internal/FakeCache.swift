import CoreGraphics

/// A fake cache that can be used to disable caching.
final class FakeCache: CacheTree {

    var name: String
    var signpostRef: AnyObject
    var screenScale: CGFloat

    init(name: String, signpostRef: AnyObject, screenScale: CGFloat) {
        self.name = name
        self.signpostRef = signpostRef
        self.screenScale = screenScale
    }

    subscript(constraint: SizeConstraint) -> CGSize? {
        get { nil }
        set {}
    }

    func subcache(key: SubcacheKey, name: @autoclosure () -> String) -> CacheTree {
        FakeCache(name: name(), signpostRef: signpostRef, screenScale: screenScale)
    }
}
