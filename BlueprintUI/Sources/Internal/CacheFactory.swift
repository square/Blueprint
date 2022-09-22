import Foundation

enum CacheFactory {
    static func makeCache(name: String, content: () -> ElementContent, signpostRef: AnyObject = SignpostToken()) -> CacheTree {
        // to disable caching, use this instead:
        // FakeCache(name: name, signpostRef: signpostRef)

        RenderPassCache(name: name, content: content(), signpostRef: signpostRef)
    }
}

/// A token reference type that can be used to group associated signpost logs using `OSSignpostID`.
private final class SignpostToken {}
