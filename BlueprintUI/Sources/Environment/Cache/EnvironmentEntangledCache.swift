import Foundation

private let assertResults = true

/// Simple dictionary-like key value cache with enforcement around environment consistency.
@_spi(CacheStorage) public struct EnvironmentEntangledCache<Key: Hashable, Value>: Sendable {

    private var storage: [Key: (FrozenEnvironment, Value)] = [:]

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
        if let (storedEnvironment, storedValue) = storage[key] {
            if environment.isEquivalent(to: storedEnvironment, in: context) {
                if assertResults, let stored = storedValue as? (any Equatable) {
                    let fresh = create() as! Equatable
                    assert(stored.isEqual(fresh))
                }
                return storedValue
            } else {
                storage.removeValue(forKey: key)
            }
        }
        let fresh = create()
        storage[key] = (environment.frozen, fresh)
        return fresh
    }

    public mutating func removeValue(forKey key: Key) -> Value? {
        storage.removeValue(forKey: key)?.1
    }

}


@_spi(CacheStorage) public struct ValidatingCache<Key, Value, ValidationData>: Sendable where Key: Hashable {

    private var storage: [Key: ValueStorage] = [:]

    private struct ValueStorage {
        let value: Value
        let validationData: ValidationData
    }

    public subscript(uncheckedKey key: Key) -> Value? {
        storage[key]?.value
    }

    public mutating func retrieveOrCreate(
        key: Key,
        validate: (ValidationData) -> Bool,
        create: () -> (Value, ValidationData)
    ) -> Value {
        if let valueStorage = storage[key] {
            if validate(valueStorage.validationData) {
                if assertResults, let stored = valueStorage.value as? (any Equatable) {
                    let fresh = create().0 as! Equatable
                    assert(stored.isEqual(fresh))
                }
                return valueStorage.value
            } else {
                storage.removeValue(forKey: key)
            }
        }
        let (fresh, validationData) = create()
        storage[key] = ValueStorage(value: fresh, validationData: validationData)
        return fresh
    }

    public mutating func removeValue(forKey key: Key) -> Value? {
        storage.removeValue(forKey: key)?.value
    }

}

extension ValidatingCache where ValidationData == FrozenEnvironment {

    mutating func retrieveOrCreate(
        key: Key,
        environment: Environment,
        context: EquivalencyContext,
        create: () -> Value
    ) -> Value {
        retrieveOrCreate(key: key) {
            environment.isEquivalent(to: $0, in: context)
        } create: {
            (create(), environment.frozen)
        }
    }

}

struct EnvironmentEntangled {
    let environment: FrozenEnvironment
    let value: AnyHashable
}

extension ValidatingCache where ValidationData == EnvironmentEntangled {

    mutating func retrieveOrCreate(
        key: Key,
        environment: Environment,
        context: EquivalencyContext,
        validationValue: AnyHashable,
        create: () -> Value
    ) -> Value {
        retrieveOrCreate(key: key) {
            environment.isEquivalent(to: $0.environment, in: context) && validationValue == $0.value
        } create: {
            (create(), .init(environment: environment.frozen, value: validationValue))
        }
    }

}


extension Equatable {

    fileprivate func isEqual(_ other: any Equatable) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return self == other
    }

}
