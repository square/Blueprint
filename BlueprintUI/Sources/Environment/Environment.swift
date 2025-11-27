import Foundation
import UIKit

/// Environment is a container for values to be passed down an element tree.
///
/// Environment values are not resolved until the tree is being rendered, so they do not need to be
/// explicitly passed to elements at the time they are created.
///
/// Environment key-value pairs are strongly typed: keys are types conforming to the
/// `EnvironmentKey` protocol, and each key's value is the type of that key's
/// `EnvironmentKey.Value` associated value. Keys must provide a default value.
///
/// ## Example
///
/// To set an environment value, so that it will cascade to child elements, use
/// `AdaptedEnvironment`. Here, every element in `childElement` will have access to `someValue`
/// via the key `MyEnvironmentKey`.
///
///     AdaptedEnvironment(
///         key: MyEnvironmentKey.self,
///         value: someValue,
///         wrapping: childElement
///     )
///
/// To read an environment value, use `EnvironmentReader`. If this element were part of the child
/// element in the previous example, `myValue` would be set to `someValue`. If the key had not
/// been set in an ancestor element, the value would be `MyEnvironmentKey.defaultValue`.
///
///     struct MyElement: ProxyElement {
///         var elementRepresentation: Element {
///             return EnvironmentReader { environment -> Element in
///                 let myValue = environment[MyEnvironmentKey.self]
///                 return SomeElement(using: myValue)
///             }
///         }
///     }
public struct Environment {

    /// A default "empty" environment, with no values overridden.
    /// Each key will return its default value.
    public static let empty = Environment()

    // Fingerprint used for referencing previously compared environments.
    var fingerprint = ComparableFingerprint()

    private var values: [Keybox: Any] = [:]
    private var snapshotting: SnapshottingEnvironment?

    // Internal values are hidden from consumers and do not participate in cross-layout cacheability checks.
    private var internalValues: [ObjectIdentifier: Any] = [:]

    /// Gets or sets an environment value by its key.
    public subscript<Key>(key: Key.Type) -> Key.Value where Key: EnvironmentKey {
        get {
            self[Keybox(key)] as! Key.Value
        }
        set {
            let keybox = Keybox(key)
            let oldValue = values[keybox]
            values[keybox] = newValue
            fingerprint.modified()
        }
    }

    private subscript(keybox: Keybox) -> Any {
        let value = values[keybox, default: keybox.type.defaultValue]
        if let snapshotting {
            snapshotting.value.values[keybox] = value
        }
        return value
    }

    subscript<Key>(key: Key.Type) -> Key.Value where Key: InternalEnvironmentKey {
        get {
            internalValues[ObjectIdentifier(key), default: key.defaultValue] as! Key.Value
        }
        set {
            internalValues[ObjectIdentifier(key)] = newValue
        }
    }

    /// If the `Environment` contains any values.
    var isEmpty: Bool {
        values.isEmpty
    }

    /// Returns a new `Environment` by merging the values from `self` and the
    /// provided environment; keeping values from the provided environment when there
    /// are key overlaps between the two environments.
    func merged(prioritizing other: Environment) -> Environment {
        var merged = self
        merged.values.merge(other.values) { $1 }
        merged.fingerprint.modified()
        return merged
    }

    func snapshottingAccess<T>(_ closure: (Environment) -> T) -> (T, EnvironmentSnapshot) {
        var watching = self
        let snapshotting = SnapshottingEnvironment()
        watching.snapshotting = snapshotting
        let result = closure(watching)
        return (result, snapshotting.value)
    }

}

/// An environment snapshot is immutable copy of the comparable elements of an Environment struct that were accessed during the cached value's creaton..
struct EnvironmentSnapshot {

    // Fingerprint used for referencing previously compared environments.
    var fingerprint: ComparableFingerprint
    var values: [Environment.Keybox: Any]

}

private final class SnapshottingEnvironment {
    var value = EnvironmentSnapshot(fingerprint: .init(), values: [:])
}

extension Environment: CrossLayoutCacheable {

    public func isCacheablyEquivalent(to other: Self?, in context: CrossLayoutCacheableContext) -> Bool {
        guard let other else { return false }
        if fingerprint.isCacheablyEquivalent(to: other.fingerprint) {
            Logger.logEnvironmentEquivalencyFingerprintEqual(environment: self)
            return true
        }
        if let evaluated = cacheStorage.environmentComparisonCache[fingerprint, other.fingerprint, context] {
            Logger.logEnvironmentEquivalencyFingerprintCacheHit(environment: self)
            return evaluated
        }
        Logger.logEnvironmentEquivalencyFingerprintCacheMiss(environment: self)
        let token = Logger.logEnvironmentEquivalencyComparisonStart(environment: self)
        let keys = Set(values.keys).union(other.values.keys)
        for key in keys {
            guard key.isCacheablyEquivalent(self[key], other[key], context) else {
                cacheStorage.environmentComparisonCache[fingerprint, other.fingerprint, context] = false
                Logger.logEnvironmentEquivalencyCompletedWithNonEquivalence(
                    environment: self,
                    key: key,
                    context: context
                )
                Logger.logEnvironmentEquivalencyComparisonEnd(token, environment: self)
                return false
            }
        }
        Logger.logEnvironmentEquivalencyComparisonEnd(token, environment: self)
        Logger.logEnvironmentEquivalencyCompletedWithEquivalence(environment: self, context: context)
        cacheStorage.environmentComparisonCache[fingerprint, other.fingerprint, context] = true
        return true
    }

    func isCacheablyEquivalent(to snapshot: EnvironmentSnapshot?, in context: CrossLayoutCacheableContext) -> Bool {
        guard let snapshot else { return false }
        // We don't even need to thaw the environment if the fingerprints match.
        if snapshot.fingerprint.isCacheablyEquivalent(to: fingerprint) {
            Logger.logEnvironmentEquivalencyFingerprintEqual(environment: self)
            return true
        }
        let scope = Set(snapshot.values.keys.map(\.objectIdentifier))
        if let evaluated = cacheStorage.environmentComparisonCache[fingerprint, snapshot.fingerprint, context, scope] {
            Logger.logEnvironmentEquivalencyFingerprintCacheHit(environment: self)
            return evaluated
        }
        Logger.logEnvironmentEquivalencyFingerprintCacheMiss(environment: self)
        let token = Logger.logEnvironmentEquivalencyComparisonStart(environment: self)
        for (key, value) in snapshot.values {
            guard key.isCacheablyEquivalent(self[key], value, context) else {
                cacheStorage.environmentComparisonCache[fingerprint, snapshot.fingerprint, context, scope] = false
                Logger.logEnvironmentEquivalencyCompletedWithNonEquivalence(
                    environment: self,
                    key: key,
                    context: context
                )
                Logger.logEnvironmentEquivalencyComparisonEnd(token, environment: self)
                return false
            }
        }
        Logger.logEnvironmentEquivalencyComparisonEnd(token, environment: self)
        Logger.logEnvironmentEquivalencyCompletedWithEquivalence(environment: self, context: context)
        cacheStorage.environmentComparisonCache[fingerprint, snapshot.fingerprint, context, scope] = true
        return true

    }


}

extension CacheStorage {

    fileprivate struct EnvironmentFingerprintCache {

        struct Key: Hashable {
            let lhs: ComparableFingerprint.Value
            let rhs: ComparableFingerprint.Value
            let scope: Set<ObjectIdentifier>?

            init(_ lhs: ComparableFingerprint.Value, _ rhs: ComparableFingerprint.Value, scope: Set<ObjectIdentifier>?) {
                // Sort lhs/rhs so we don't have diff results based on caller.
                self.lhs = min(lhs, rhs)
                self.rhs = max(lhs, rhs)
                self.scope = scope
            }
        }

        typealias EquivalencyResult = [CrossLayoutCacheableContext: Bool]
        var storage: [Key: [CrossLayoutCacheableContext: Bool]] = [:]

        public subscript(
            lhs: ComparableFingerprint,
            rhs: ComparableFingerprint,
            context: CrossLayoutCacheableContext,
            scope: Set<ObjectIdentifier>? = nil
        ) -> Bool? {
            get {
                let key = Key(lhs.value, rhs.value, scope: scope)
                if let exact = storage[key]?[context] {
                    return exact
                } else if let allComparisons = storage[key] {
                    switch context {
                    case .all:
                        // If we're checking for equivalency in ALL contexts, we can short circuit based on any case where equivalency is false.
                        if allComparisons.contains(where: { $1 == false }) {
                            return false
                        } else {
                            return nil
                        }
                    case .elementSizing:
                        // If we've already evaluated it to be equivalent in all cases, we can short circuit because we know that means any more specific checks must also be equivalent
                        if allComparisons[.all] == true {
                            return true
                        } else {
                            return nil
                        }
                    }
                } else {
                    return nil
                }
            }
            set {
                storage[Key(lhs.value, rhs.value, scope: scope), default: [:]][context] = newValue
            }
        }

    }

    /// A cache of previously compared environments and their results.
    private struct EnvironmentComparisonCrossLayoutCacheKey: CrossLayoutCacheKey {
        static var emptyValue = EnvironmentFingerprintCache()
    }

    fileprivate var environmentComparisonCache: EnvironmentFingerprintCache {
        get { self[EnvironmentComparisonCrossLayoutCacheKey.self] }
        set { self[EnvironmentComparisonCrossLayoutCacheKey.self] = newValue }
    }

}

extension Environment {

    /// Lightweight key type eraser.
    struct Keybox: Hashable, CustomStringConvertible {

        let objectIdentifier: ObjectIdentifier
        let type: any EnvironmentKey.Type
        let isCacheablyEquivalent: (Any?, Any?, CrossLayoutCacheableContext) -> Bool

        init<EnvironmentKeyType: EnvironmentKey>(_ type: EnvironmentKeyType.Type) {
            objectIdentifier = ObjectIdentifier(type)
            self.type = type
            isCacheablyEquivalent = {
                guard let lhs = $0 as? EnvironmentKeyType.Value, let rhs = $1 as? EnvironmentKeyType.Value else { return false }
                return type.isCacheablyEquivalent(lhs: lhs, rhs: rhs, in: $2)
            }
        }

        func hash(into hasher: inout Hasher) {
            objectIdentifier.hash(into: &hasher)
        }

        static func == (lhs: Keybox, rhs: Keybox) -> Bool {
            lhs.objectIdentifier == rhs.objectIdentifier
        }

        var description: String {
            String(describing: type)
        }

    }

}

extension UIView {

    /// The ``Environment`` for the ``Element`` that this view represents in a Blueprint element tree,
    /// or if the view is not explicitly managed by Blueprint, the ``Environment`` of
    /// the nearest superview that is managed by Blueprint.
    ///
    /// If no views in the superview hierarchy are managed by Blueprint, this property returns nil.
    var inheritedBlueprintEnvironment: Environment? {
        if let environment = nativeViewNodeBlueprintEnvironment {
            return environment
        } else if let superview = superview {
            return superview.inheritedBlueprintEnvironment
        } else {
            return nil
        }
    }

    /// The ``Environment`` for the ``Element`` that this view represents in a Blueprint element tree.
    ///
    /// If this view is not managed by Blueprint, this property returns nil.
    var nativeViewNodeBlueprintEnvironment: Environment? {
        get {
            objc_getAssociatedObject(self, &UIView.environmentKey) as? Environment ?? nil
        }
        set {
            objc_setAssociatedObject(self, &UIView.environmentKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    private static var environmentKey: UInt8 = 0
}
