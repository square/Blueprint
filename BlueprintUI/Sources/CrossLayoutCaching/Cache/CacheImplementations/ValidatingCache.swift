import Foundation
import Collections

/// Validating cache is a cache which, if it has a value for a key, runs a closure to verify that the cache value is still relevant and not state.
/// This is useful for cases when you might otherwise wish to store the validation data as a key, but it does not conform to Hashable, or its hashability properties do not neccessarily affect the validity of the cached data.
@_spi(HostingViewContext) public struct ValidatingCache<Key, Value, ValidationData>: Sendable where Key: Hashable {

    private var storage: TreeDictionary<Key, ValueStorage> = [:]

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
            Logger.logValidatingCrossLayoutCacheKeyHit(key: key)
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
            Logger.logValidatingCrossLayoutCacheKeyMiss(key: key)
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

extension Equatable {

    fileprivate func isEqual(_ other: any Equatable) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return self == other
    }

}
