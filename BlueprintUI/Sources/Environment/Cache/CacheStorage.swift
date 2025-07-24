import Foundation

/// Environment-associated storage used to cache types used across layout passes (eg, size calculations).
/// The storage itself is type-agnostic, requiring only that its keys and values conform to the `CacheKey` protocol
/// Caches are responsible for managing their own lifetimes and eviction strategies.
@_spi(CacheStorage) public final class CacheStorage: Sendable, CustomDebugStringConvertible {

    // Optional name to distinguish between instances for debugging purposes.
    public var name: String? = nil
    fileprivate var storage: [ObjectIdentifier: Any] = [:]
    fileprivate var currentEnvironment: FrozenEnvironment? = nil

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

public final class CacheStorageInternal {

    private var storage: [ObjectIdentifier: Any] = [:]

    init(_ cacheStorage: CacheStorage) {
        storage = cacheStorage.storage
    }

    init() {
        storage = [:]
    }

    func current(with environment: Environment?) -> CacheStorage {
        var storage = CacheStorage()
        storage.storage = self.storage
//        storage.currentEnvironment = environment
        return storage
    }

}

extension Environment {

    struct CacheStorageEnvironmentKey: InternalEnvironmentKey {
        static var defaultValue = CacheStorageInternalEnvironmentKey.defaultValue.current(with: nil)
    }

    private struct CacheStorageInternalEnvironmentKey: InternalEnvironmentKey {
        static var defaultValue = CacheStorageInternal()
    }

    @_spi(CacheStorage) public var cacheStorage: CacheStorage {
        get { self[internal: CacheStorageEnvironmentKey.self] }
        set { self[internal: CacheStorageEnvironmentKey.self] = newValue }
//        get { self[internal: CacheStorageInternalEnvironmentKey.self].current(with: self) }
//        set { self[internal: CacheStorageInternalEnvironmentKey.self] = .init(newValue) }
    }

}

/// A frozen environment is immutable copy of the comparable elements of an Environment struct.
struct FrozenEnvironment {

    // Fingerprint used for referencing previously compared environments.
    let fingerprint: ComparableFingerprint
    let values: [Environment.Keybox: Any]

}

struct ComparableFingerprint: Hashable {

    private var fingerprint: UUID

    init() {
        fingerprint = UUID()
    }

    mutating func modified() {
        fingerprint = UUID()
    }

}

