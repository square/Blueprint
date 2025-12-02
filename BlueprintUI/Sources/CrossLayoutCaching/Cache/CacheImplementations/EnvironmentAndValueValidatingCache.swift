import Foundation

/// A convenience wrapper around ValidatingCache which ensures that only values which were cached in equivalent environments are returned, and allows for additional data to be stored to be validated.
@_spi(HostingViewContext) public final class EnvironmentAndValueValidatingCache<Key, Value, AdditionalValidationData>: Sendable where Key: Hashable & Sendable {

    private var backing = ValidatingCache<Key, Value, (EnvironmentAccessList, AdditionalValidationData)>()

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
    func retrieveOrCreate(
        key: Key,
        environment: Environment,
        context: CrossLayoutCacheableContext,
        validate: (AdditionalValidationData) -> Bool,
        create: (Environment) -> (Value, AdditionalValidationData)
    ) -> Value {
        backing.retrieveOrCreate(key: key) {
            environment.isCacheablyEquivalent(to: $0.0, in: context) && validate($0.1)
        } create: {
            let ((value, additional), accessList) = environment.observingAccess { environment in
                create(environment)
            }
            return (value, (accessList, additional))
        }
    }

}

@_spi(HostingViewContext) extension EnvironmentAndValueValidatingCache where AdditionalValidationData: CrossLayoutCacheable {

    /// Retrieves or creates a value based on a key and a validation value, alongside environment validation.
    /// - Parameters:
    ///   - key: The key to look up.
    ///   - environment: The current environment. A frozen version of this environment will be preserved along with freshly cached values for comparison.
    ///   - context: The equivalency context in which the environment and validation values should be evaluated.
    ///   - validationValue: A value that will be compared using contextual equivalence that evaluates whether or not a given result is still valid.
    ///   - create: Creates a fresh cache entry no valid cached data is available, and stores it.
    /// - Returns: Either a cached or newly created value.
    public func retrieveOrCreate(
        key: Key,
        environment: Environment,
        validationValue: AdditionalValidationData,
        context: CrossLayoutCacheableContext,
        create: (Environment) -> (Value)
    ) -> Value {
        retrieveOrCreate(key: key, environment: environment, context: context) {
            $0.isCacheablyEquivalent(to: validationValue, in: context)
        } create: {
            (create($0), validationValue)
        }

    }

}

@_spi(HostingViewContext) extension EnvironmentAndValueValidatingCache where AdditionalValidationData: Equatable {

    /// Retrieves or creates a value based on a key and a validation value, alongside environment validation.
    /// - Parameters:
    ///   - key: The key to look up.
    ///   - environment: The current environment. A frozen version of this environment will be preserved along with freshly cached values for comparison.
    ///   - context: The equivalency context in which the environment should be evaluated.
    ///   - validationValue: A value that will be compared using strict equality that evaluates whether or not a given result is still valid.
    ///   - create: Creates a fresh cache entry no valid cached data is available, and stores it.
    /// - Returns: Either a cached or newly created value.
    @_disfavoredOverload public func retrieveOrCreate(
        key: Key,
        environment: Environment,
        validationValue: AdditionalValidationData,
        context: CrossLayoutCacheableContext,
        create: (Environment) -> (Value)
    ) -> Value {
        retrieveOrCreate(key: key, environment: environment, context: context) {
            $0 == validationValue
        } create: {
            (create($0), validationValue)
        }
    }

}

