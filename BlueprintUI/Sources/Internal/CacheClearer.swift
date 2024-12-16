import Foundation

@_spi(CacheManagement)
public struct CacheClearer {

    /// Clears all static caches that are in use.
    ///
    /// Blueprint leverages static caching to improve performance however there are situations in which
    /// this can cause object lifetimes to be extended unexpectedly, especially in cases where cached
    /// views reference other objects.
    ///
    /// - WARNING: Clearing these caches can have global performance implications. This method
    /// should be invoked sparingley and only after other workarounds to manage object lifetimes have failed.
    @_spi(CacheManagement)
    public static func clearStaticCaches() {
        UIViewElementMeasurer.shared.removeAllObjects()
    }
}
