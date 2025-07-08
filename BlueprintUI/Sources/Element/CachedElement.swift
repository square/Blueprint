import UIKit

private final class CacheBox {

    fileprivate struct CacheStorage {
        let environment: Environment
        let value: Any
    }

    var caches: [AnyHashable: CacheStorage] = [:]
}

private var _cacheBox = CacheBox()

public struct CachedElement<CacheType>: ProxyElement {

    /// Return the contents of this element in the given environment.
    let _elementRepresentation: (inout CacheType) -> Element
    let createCache: (CacheType?) -> CacheType
    let cacheID: AnyHashable
    let environmentInvalidationContext: EquivalencyContext

    public init(
        cacheID: AnyHashable = ObjectIdentifier(CacheType.self),
        environmentInvalidationContext: EquivalencyContext = .all,
        elementRepresentation: @escaping (_ cache: inout CacheType) -> Element,
        createCache: @escaping (CacheType?) -> CacheType
    ) {
        self.cacheID = cacheID
        self.environmentInvalidationContext = environmentInvalidationContext
        self.createCache = createCache
        _elementRepresentation = elementRepresentation
    }

    public var elementRepresentation: any Element {
        EnvironmentReader { environment in
            let existing = _cacheBox.caches[cacheID]
            var cache: CacheType
            if let existing, environment.isEquivalent(to: existing.environment, in: environmentInvalidationContext) {
                cache = existing.value as! CacheType
            } else {
                let fresh = createCache(existing?.value as? CacheType)
                _cacheBox.caches[cacheID] = CacheBox.CacheStorage(environment: environment, value: fresh)
                cache = fresh
            }
            let rep = _elementRepresentation(&cache)
            _cacheBox.caches[cacheID] = CacheBox.CacheStorage(environment: environment, value: cache)
            return rep
        }
    }

}
