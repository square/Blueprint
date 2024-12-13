import Foundation

extension Environment {
    private enum ViewCacheKey: EnvironmentKey {
        static let defaultValue: TypeKeyedCache? = nil
    }

    private static let fallback = TypeKeyedCache()

    var inheritedViewCache: TypeKeyedCache? {
        self[ViewCacheKey.self]
    }

    public internal(set) var viewCache: TypeKeyedCache {
        get {
            if let inheritedViewCache {
                return inheritedViewCache
            } else {
                #if DEBUG
                do {
                    /// Set a breakpoint on this `throw` if you'd like to understand where this error is occurring.
                    ///
                    /// We throw a caught error so that program execution can continue, and folks can opt
                    /// in or out of stopping on the error.
                    throw ViewCacheErrors.fallingBackToStaticCache
                } catch {

                    /// **Warning**: Blueprint is falling back to a static `TypeKeyedCache`,
                    /// which will result in prototype measurement values being retained for
                    /// the lifetime of the application, which can result in memory leaks.
                    ///
                    /// If you are seeing this error, ensure you're passing the Blueprint `Environment`
                    /// properly through your element hierarchies – you should almost _never_ be
                    /// passing an `.empty` environment to methods, and instead passing an inherited
                    /// environment which will be passed to you by callers or a parent view controller,
                    /// screen, or element.
                    ///
                    /// To learn more, see https://github.com/square/Blueprint/tree/main/Documentation/TODO.md.

                }
                #endif

                return Self.fallback
            }
        }

        set {
            self[ViewCacheKey.self] = newValue
        }
    }

    private enum ViewCacheErrors: Error {
        case fallingBackToStaticCache
    }
}
