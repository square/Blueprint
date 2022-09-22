import CoreGraphics

/// A fake cache that can be used to disable caching.
final class FakeCache: CacheTree {

    var name: String
    var signpostRef: AnyObject

    var content: ElementContent

    init(name: String, content: ElementContent, signpostRef: AnyObject) {
        self.name = name
        self.signpostRef = signpostRef
        self.content = content
    }

    subscript(constraint: SizeConstraint) -> CGSize? {
        get { nil }
        set {}
    }

    func subcache(key: SubcacheKey, content: @autoclosure () -> ElementContent, name: @autoclosure () -> String) -> CacheTree {
        FakeCache(name: name(), content: content(), signpostRef: signpostRef)
    }
}
