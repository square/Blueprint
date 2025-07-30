import Foundation

/// Validating cache is a cache which, if it has a value for a key, runs a closure to verify that the cache value is still relevant and not state.
/// This is useful for cases when you might otherwise wish to store the validation data as a key, but it does not conform to Hashable, or its hashability properties do not neccessarily affect the validity of the cached data.
@_spi(CacheStorage) public struct ValidatingCache<Key, Value, ValidationData>: Sendable where Key: Hashable {

    private var storage: [Key: ValueStorage] = [:]

    private struct ValueStorage {
        let value: Value
        let validationData: ValidationData
    }

    public init() {}

    /// Retrieves the value for a given key, without evaluating any validation conditions.
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
            Logger.logValidatingCacheKeyHit(key: key)
            let validationToken = Logger.logValidatingCacheValidationStart(key: key)
            if validate(valueStorage.validationData) {
                Logger.logValidatingCacheHitAndValidationSuccess(key: key)
                Logger.logValidatingCacheValidationEnd(validationToken, key: key)
                return valueStorage.value
                #if DEBUG
                // FIXME: WAY TO MAKE SURE THIS DOESN'T SHIP ON.
                // Enable this to always evaluate the create block to assert that the caching is producing the expected value.
                //                if let stored = valueStorage.value as? (any Equatable) {
                //                    let fresh = create().0 as! Equatable
                //                    assert(stored.isEqual(fresh))
                //                }
                // return valueStorage.value
                #endif
            } else {
                Logger.logValidatingCacheHitAndValidationFailure(key: key)
                Logger.logValidatingCacheValidationEnd(validationToken, key: key)
            }
        } else {
            Logger.logValidatingCacheKeyMiss(key: key)
        }
        let createToken = Logger.logValidatingCacheFreshValueCreationStart(key: key)
        let (fresh, validationData) = create()
        Logger.logValidatingCacheFreshValueCreationEnd(createToken, key: key)
        storage[key] = ValueStorage(value: fresh, validationData: validationData)
        return fresh
    }

    public mutating func removeValue(forKey key: Key) -> Value? {
        storage.removeValue(forKey: key)?.value
    }

}

/// A convenience wrapper around ValidatingCache which ensures that only values which were cached in equivalent environments are returned.
@_spi(CacheStorage) public struct EnvironmentValidatingCache<Key, Value>: Sendable where Key: Hashable {

    private var backing = ValidatingCache<Key, Value, EnvironmentSnapshot>()

    public init() {}

    /// Retrieves or creates a value based on a key and environment validation.
    /// - Parameters:
    ///   - key: The key to look up.
    ///   - environment: The current environment. A frozen version of this environment will be preserved along with freshly cached values for comparison.
    ///   - context: The equivalency context in which the environment should be evaluated.
    ///   - create: Creates a fresh cache entry no valid cached data is available, and stores it.
    /// - Returns: Either a cached or newly created value.
    mutating func retrieveOrCreate(
        key: Key,
        environment: Environment,
        context: EquivalencyContext,
        create: (Environment) -> Value
    ) -> Value {
        backing.retrieveOrCreate(key: key) {
            environment.isEquivalent(to: $0, in: context)
        } create: {
            environment.snapshottingAccess { environment in
                create(environment)
            }
        }
    }

}

/// A convenience wrapper around ValidatingCache which ensures that only values which were cached in equivalent environments are returned, and allows for additional data to be stored to be validated.
@_spi(CacheStorage) public struct EnvironmentAndValueValidatingCache<Key, Value, AdditionalValidationData>: Sendable where Key: Hashable {

    private var backing = ValidatingCache<Key, Value, (EnvironmentSnapshot, AdditionalValidationData)>()

    public init() {}

    /// Retrieves or creates a value based on a key and a validation function, alongside environment validation.
    /// - Parameters:
    ///   - key: The key to look up.
    ///   - environment: The current environment. A frozen version of this environment will be preserved along with freshly cached values for comparison.
    ///   - context: The equivalency context in which the environment should be evaluated.
    ///   - validate: A function that evaluates whether or not a given result is still valid.
    ///   - create: Creates a fresh cache entry no valid cached data is available, and stores it.
    /// - Returns: Either a cached or newly created value.
    /// - Note: Generally, prefer the `validationValue` versions of this method if the validation value conforms to ContextuallyEquivalent or Equatable.
    mutating func retrieveOrCreate(
        key: Key,
        environment: Environment,
        context: EquivalencyContext,
        validate: (AdditionalValidationData) -> Bool,
        create: (Environment) -> (Value, AdditionalValidationData)
    ) -> Value {
        backing.retrieveOrCreate(key: key) {
            environment.isEquivalent(to: $0.0, in: context) && validate($0.1)
        } create: {
            let x = environment.snapshottingAccess { environment in
                create(environment)
            }
            return (x.0.0, (x.1, x.0.1))
        }
    }

}


@_spi(CacheStorage) extension EnvironmentAndValueValidatingCache where AdditionalValidationData: ContextuallyEquivalent {

    /// Retrieves or creates a value based on a key and a validation value, alongside environment validation.
    /// - Parameters:
    ///   - key: The key to look up.
    ///   - environment: The current environment. A frozen version of this environment will be preserved along with freshly cached values for comparison.
    ///   - context: The equivalency context in which the environment and validation values should be evaluated.
    ///   - validationValue: A value that will be compared using contextual equivalence that evaluates whether or not a given result is still valid.
    ///   - create: Creates a fresh cache entry no valid cached data is available, and stores it.
    /// - Returns: Either a cached or newly created value.
    public mutating func retrieveOrCreate(
        key: Key,
        environment: Environment,
        validationValue: AdditionalValidationData,
        context: EquivalencyContext,
        create: (Environment) -> (Value)
    ) -> Value {
        retrieveOrCreate(key: key, environment: environment, context: context) {
            $0.isEquivalent(to: validationValue, in: context)
        } create: {
            (create($0), validationValue)
        }

    }

}

@_spi(CacheStorage) extension EnvironmentAndValueValidatingCache where AdditionalValidationData: Equatable {

    /// Retrieves or creates a value based on a key and a validation value, alongside environment validation.
    /// - Parameters:
    ///   - key: The key to look up.
    ///   - environment: The current environment. A frozen version of this environment will be preserved along with freshly cached values for comparison.
    ///   - context: The equivalency context in which the environment should be evaluated.
    ///   - validationValue: A value that will be compared using strict equality that evaluates whether or not a given result is still valid.
    ///   - create: Creates a fresh cache entry no valid cached data is available, and stores it.
    /// - Returns: Either a cached or newly created value.
    @_disfavoredOverload public mutating func retrieveOrCreate(
        key: Key,
        environment: Environment,
        validationValue: AdditionalValidationData,
        context: EquivalencyContext,
        create: (Environment) -> (Value)
    ) -> Value {
        retrieveOrCreate(key: key, environment: environment, context: context) {
            $0 == validationValue
        } create: {
            (create($0), validationValue)
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
