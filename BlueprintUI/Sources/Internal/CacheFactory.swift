import Foundation

enum CacheFactory {
    static func makeCache(name: String, signpostRef: AnyObject = SignpostToken()) -> CacheTree {
        // to disable caching, use this instead:
        //FakeCache(name: name, signpostRef: signpostRef)

        RenderPassCache(name: name, signpostRef: signpostRef)
    }
}

private final class SignpostToken { }
