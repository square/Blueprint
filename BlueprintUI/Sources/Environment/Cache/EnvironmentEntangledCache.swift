import Foundation

/// Simple dictionary-like key value cache with enforcement around environment consistency.
@_spi(CacheStorage) public struct EnvironmentEntangledCache<Key: Hashable, Value>: Sendable {

    private var storage: [Key: (Environment, Value)] = [:]

    public subscript(uncheckedKey key: Key) -> Value? {
        storage[key]?.1
    }

    /// Retrieves a value if one exists in the cache for a given environment and equivalency context.
    /// - Parameters:
    ///   - key: The key to look up.
    ///   - environment: The environment being evaluated.
    ///   - context: The context in which the environment is being evaluated in.
    ///   - create: A closure to create a fresh value if no suitable cached value is available.
    /// - Returns: A cached or freshly created value.
    /// - Note: If no value exists for the key, or a value exists for the key but the environment does not meet the require equivalency, any existing value will be evicted from the cache and a fresh value will be created and stored.
    public mutating func retrieveOrCreate(
        key: Key,
        environment: Environment,
        context: EquivalencyContext,
        create: () -> Value
    ) -> Value {
        if let existing = storage[key] {
            if existing.0.isEquivalent(to: environment, in: context) {
                return existing.1
            } else {
                storage.removeValue(forKey: key)
            }
        }
        let fresh = create()
        storage[key] = (environment, fresh)
        return fresh
    }

    public mutating func removeValue(forKey key: Key) -> Value? {
        storage.removeValue(forKey: key)?.1
    }

}

