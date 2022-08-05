import CoreGraphics

/// A fake cache that can be used to disable caching.
final class FakeCache: CacheTree {

    var name: String
    var signpostRef: AnyObject

    init(name: String, signpostRef: AnyObject) {
        self.name = name
        self.signpostRef = signpostRef
    }

    subscript(constraint: SizeConstraint) -> CGSize? {
        get { nil }
        set {}
    }

    func subcache(key: SubcacheKey, name: @autoclosure () -> String) -> CacheTree {
        FakeCache(name: name(), signpostRef: signpostRef)
    }
}
