import Foundation

private let assertResults = true

/// Validating cache is a cache which, if it has a value for a key, runs a closure to verify that the cache value is still relevant and not state.
/// This is useful for cases when you might otherwise wish to store the validation data as a key, but it does not conform to Hashable, or its hashability properties do not neccessarily affect the validity of the cached data.
@_spi(CacheStorage) public struct ValidatingCache<Key, Value, ValidationData>: Sendable where Key: Hashable {

    private var storage: [Key: ValueStorage] = [:]

    private struct ValueStorage {
        let value: Value
        let validationData: ValidationData
    }

    public subscript(uncheckedKey key: Key) -> Value? {
        storage[key]?.value
    }

    /// Retrieves or creates a value based on a key and validation function.
    /// - Parameters:
    ///   - key: The key to look up.
    ///   - validate: A function that evaluates whether or not a given result is still valid.
    ///   - create: Creates a fresh cache entry no valid cached data is available, and stores it.
    /// - Returns: Either a cached or newly created value.
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

/// A convenience wrapper around ValidatingCache which ensures that only values which were cached in equivalent environments are returned.
@_spi(CacheStorage) public struct EnvironmentValidatingCache<Key, Value>: Sendable where Key: Hashable {

    var backing = ValidatingCache<Key, Value, FrozenEnvironment>()

    mutating func retrieveOrCreate(
        key: Key,
        environment: Environment,
        context: EquivalencyContext,
        create: () -> Value
    ) -> Value {
        backing.retrieveOrCreate(key: key) {
            environment.isEquivalent(to: $0, in: context)
        } create: {
            (create(), environment.frozen)
        }
    }

}

/// A convenience wrapper around ValidatingCache which ensures that only values which were cached in equivalent environments are returned, and allows for additional data to be stored to be validated.
@_spi(CacheStorage) public struct EnvironmentAndValueValidatingCache<Key, Value, AdditionalValidationData>: Sendable where Key: Hashable {

    var backing = ValidatingCache<Key, Value, (FrozenEnvironment, AdditionalValidationData)>()

    mutating func retrieveOrCreate(
        key: Key,
        environment: Environment,
        context: EquivalencyContext,
        validate: (AdditionalValidationData) -> Bool,
        create: () -> (Value, AdditionalValidationData)
    ) -> Value {
        backing.retrieveOrCreate(key: key) {
            environment.isEquivalent(to: $0.0, in: context) && validate($0.1)
        } create: {
            let (fresh, additional) = create()
            return (fresh, (environment.frozen, additional))
        }
    }

}


extension EnvironmentAndValueValidatingCache where AdditionalValidationData: ContextuallyEquivalent {

    mutating func retrieveOrCreate(
        key: Key,
        environment: Environment,
        validationValue: AdditionalValidationData,
        context: EquivalencyContext,
        create: () -> (Value)
    ) -> Value {
        retrieveOrCreate(key: key, environment: environment, context: context) {
            $0.isEquivalent(to: validationValue, in: context)
        } create: {
            (create(), validationValue)
        }

    }

}

extension EnvironmentAndValueValidatingCache where AdditionalValidationData: Equatable {

    @_disfavoredOverload mutating func retrieveOrCreate(
        key: Key,
        environment: Environment,
        validationValue: AdditionalValidationData,
        context: EquivalencyContext,
        create: () -> (Value)
    ) -> Value {
        retrieveOrCreate(key: key, environment: environment, context: context) {
            $0 == validationValue
        } create: {
            (create(), validationValue)
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
