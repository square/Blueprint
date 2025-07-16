import Foundation

/// Environment-associated storage used to cache types used across layout passes (eg, size calculations).
/// The storage itself is type-agnostic, requiring only that its keys and values conform to the `CacheKey` protocol
/// Caches are responsible for managing their own lifetimes and eviction strategies.
@_spi(CacheStorage) public final class CacheStorage: Sendable, CustomDebugStringConvertible {

    // Optional name to distinguish between instances for debugging purposes.
    public var name: String? = nil
    private var storage: [ObjectIdentifier: Any] = [:]

    public subscript<KeyType>(key: KeyType.Type) -> KeyType.Value where KeyType: CacheKey {
        get {
            storage[ObjectIdentifier(key), default: KeyType.emptyValue] as! KeyType.Value
        }
        set {
            storage[ObjectIdentifier(key)] = newValue
        }
    }

    public var debugDescription: String {
        if let name {
            "CacheStorage (\(name))"
        } else {
            "CacheStorage"
        }
    }

}


extension Environment {

    struct CacheStorageEnvironmentKey: InternalEnvironmentKey {
        static var defaultValue = CacheStorage()
    }

    @_spi(CacheStorage) public var cacheStorage: CacheStorage {
        get { self[internal: CacheStorageEnvironmentKey.self] }
        set { self[internal: CacheStorageEnvironmentKey.self] = newValue }
    }

}
