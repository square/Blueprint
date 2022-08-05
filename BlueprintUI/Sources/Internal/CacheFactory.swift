import Foundation

enum CacheFactory {
    static func makeCache(name: String, signpostRef: AnyObject = SignpostToken()) -> CacheTree {
        // to disable caching, use this instead:
        // FakeCache(name: name, signpostRef: signpostRef)

        RenderPassCache(name: name, signpostRef: signpostRef)
    }
}

/// A token reference type that can be used to group associated signpost logs using `OSSignpostID`.
private final class SignpostToken {}
