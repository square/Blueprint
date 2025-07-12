import Foundation

public final class CacheStorage: Sendable, CustomDebugStringConvertible {

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

    public func clear<KeyType>(key: KeyType.Type) -> KeyType.Value? where KeyType: CacheKey {
        storage.removeValue(forKey: ObjectIdentifier(key)) as? KeyType.Value
    }

    public var debugDescription: String {
        if let name {
            "CacheStorage (\(name))"
        } else {
            "CacheStorage"
        }
    }

}

public protocol CacheKey {
    associatedtype Value
    static var emptyValue: Self.Value { get }
}

extension Environment {

    struct CacheStorageEnvironmentKey: InternalEnvironmentKey {
        static var defaultValue = CacheStorage()
    }

    public var cacheStorage: CacheStorage {
        get { self[internal: CacheStorageEnvironmentKey.self] }
        set { self[internal: CacheStorageEnvironmentKey.self] = newValue }
    }

}
