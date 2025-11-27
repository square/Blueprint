import Foundation

@_spi(HostingViewContext) extension EnvironmentAndValueValidatingCache where AdditionalValidationData: CrossLayoutCacheable {

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
    @_disfavoredOverload public mutating func retrieveOrCreate(
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

