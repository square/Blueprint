import Foundation
import UIKit

/// Environment-associated storage used to cache types used across layout passes (eg, size calculations).
/// The storage itself is type-agnostic, requiring only that its keys and values conform to the `CrossLayoutCacheKey` protocol
/// Caches are responsible for managing their own lifetimes and eviction strategies.
@_spi(HostingViewContext) public final class HostingViewContext: Sendable, CustomDebugStringConvertible {

    // Optional name to distinguish between instances for debugging purposes.
    public var name: String? = nil
    fileprivate var storage: [ObjectIdentifier: Any] = [:]

    init() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.storage.removeAll()
        }
    }

    public subscript<KeyType>(key: KeyType.Type) -> KeyType.Value where KeyType: CrossLayoutCacheKey {
        get {
            storage[ObjectIdentifier(key), default: KeyType.emptyValue] as! KeyType.Value
        }
        set {
            storage[ObjectIdentifier(key)] = newValue
        }
    }

    public var debugDescription: String {
        let debugName = if let name {
            "HostingViewContext (\(name))"
        } else {
            "HostingViewContext"
        }
        return "\(debugName): \(storage.count) entries"
    }

}

extension Environment {

    struct HostingViewContextKey: InternalEnvironmentKey {
        static var defaultValue = HostingViewContext()
    }


    @_spi(HostingViewContext) public var hostingViewContext: HostingViewContext {
        get { self[HostingViewContextKey.self] }
        set { self[HostingViewContextKey.self] = newValue }
    }

}

/// A UUID that changes based on value changes of the containing type.
/// Two fingerprinted objects may be quickly compared for equality by comparing their fingerprints.
/// This is roughly analagous to a hash, although with inverted properties: Two objects with the same fingerprint can be trivially considered equal, but two otherwise equal objects may have different fingerprint.
/// - Note: This type is deliberately NOT equatable – this is to prevent accidental inclusion of it when its containing type is equatable.
struct CacheComparisonFingerprint: CrossLayoutCacheable, CustomStringConvertible {

    typealias Value = UUID

    var value: Value

    init() {
        value = Value()
    }

    mutating func modified() {
        value = Value()
    }

    /// - Note: This is a duplicate message but: this type is deliberately NOT equatable – this is to prevent accidental inclusion of it when its containing type is equatable. Use this instead.
    func isCacheablyEquivalent(to other: CacheComparisonFingerprint?, in context: CrossLayoutCacheableContext) -> Bool {
        value == other?.value
    }

    var description: String {
        value.uuidString
    }

}

