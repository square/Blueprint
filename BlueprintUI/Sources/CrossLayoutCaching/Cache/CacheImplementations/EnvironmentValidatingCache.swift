import Foundation

/// A convenience wrapper around ValidatingCache which ensures that only values which were cached in equivalent environments are returned.
@_spi(HostingViewContext) public struct EnvironmentValidatingCache<Key, Value>: Sendable where Key: Hashable {

    private var backing = ValidatingCache<Key, Value, EnvironmentAccessList>()

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
        context: CrossLayoutCacheableContext,
        create: (Environment) -> Value
    ) -> Value {
        backing.retrieveOrCreate(key: key) {
            environment.isCacheablyEquivalent(to: $0, in: context)
        } create: {
            environment.observingAccess { environment in
                create(environment)
            }
        }
    }

}

