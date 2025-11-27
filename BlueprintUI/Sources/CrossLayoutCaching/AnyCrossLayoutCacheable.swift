import Foundation

/// Type eraser for CrossLayoutCacheable.
public struct AnyCrossLayoutCacheable: CrossLayoutCacheable {

    let base: Any

    public init(_ value: some CrossLayoutCacheable) {
        base = value
    }

    public func isCacheablyEquivalent(to other: AnyCrossLayoutCacheable?, in context: CrossLayoutCacheableContext) -> Bool {
        guard let base = (base as? any CrossLayoutCacheable) else { return false }
        return base.isCacheablyEquivalent(to: other?.base as? CrossLayoutCacheable, in: context)
    }

}

