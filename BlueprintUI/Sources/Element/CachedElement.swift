import UIKit

public struct CachedElement<CacheType: CacheKey>: ProxyElement {

    /// Return the contents of this element in the given environment.
    let _elementRepresentation: (inout CacheType.Value) -> Element
    let environmentInvalidationContext: EquivalencyContext

    public init(
        environmentInvalidationContext: EquivalencyContext = .all,
        elementRepresentation: @escaping (_ cache: inout CacheType.Value) -> Element,
    ) {
        self.environmentInvalidationContext = environmentInvalidationContext
        _elementRepresentation = elementRepresentation
    }

    public var elementRepresentation: any Element {
        EnvironmentReader { environment in
            let existing = environment.cacheStorage[CacheType.self]
            var cache: CacheType.Value
            // FIXME: NOOP RN, FIX TO PREV ENV
            if environment.isEquivalent(to: /* existing. */environment, in: environmentInvalidationContext) {
                cache = existing as! CacheType.Value
            } else {
//                _cacheBox.caches[cacheID] = CacheBox.CacheStorage(environment: environment, value: fresh)
                cache = CacheType.emptyValue
                environment.cacheStorage[CacheType.self] = cache
            }
            let rep = _elementRepresentation(&cache)
            environment.cacheStorage[CacheType.self] = cache
//            _cacheBox.caches[cacheID] = CacheBox.CacheStorage(environment: environment, value: cache)
            return rep
        }
    }

}

// private struct ElementContentCacheKey: CacheKey {
//    static var emptyValue: [AnyHashable: Any] = [:]
// }
//
// var elementContentCache: [AnyHashable: Any] {
//    get { self[ElementContentCacheKey.self] }
//    set { self[ElementContentCacheKey.self] = newValue }
// }
