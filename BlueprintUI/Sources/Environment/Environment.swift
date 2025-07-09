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

    private var values: [Keybox: Any] = [:] {
        didSet {
            identity = UUID()
        }
    }

    private var internalValues: [ObjectIdentifier: Any] = [:]

    fileprivate var identity: UUID = UUID()

    /// Gets or sets an environment value by its key.
    public subscript<Key>(key: Key.Type) -> Key.Value where Key: EnvironmentKey {
        get {
            self[Keybox(key)] as! Key.Value
        }
        set {
            values[Keybox(key)] = newValue
        }
    }

    private subscript(keybox: Keybox) -> Any {
        values[keybox, default: keybox.type.defaultValue]
    }

    public subscript<Key>(internal key: Key.Type) -> Key.Value where Key: EnvironmentKey {
        get {
            internalValues[ObjectIdentifier(key)] as! Key.Value
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
        return merged
    }
}

extension Environment: ContextuallyEquivalent {

    public func isEquivalent(to other: Environment?, in context: EquivalencyContext) -> Bool {
        guard let other else { return false }
        if identity == other.identity { return true }
        if let evaluated = cacheStorage.environmentComparisonCacheKey[other.identity], let result = evaluated[context] {
            #if DEBUG
            print("Cached comparison result")
            #endif
            return result
        }
        let keys = Set(values.keys).union(other.values.keys)
        for key in keys {
            guard key.isEquivalent(self[key], other[key], context) else {
                #if DEBUG
                print(key, self[key], other[key])
                #endif
                cacheStorage.environmentComparisonCacheKey[other.identity, default: [:]][context] = false
                return false
            }
        }
        cacheStorage.environmentComparisonCacheKey[other.identity, default: [:]][context] = true
        return true
    }

}


extension CacheStorage {

    private struct EnvironmentComparisonCacheKey: CacheKey {
        static var emptyValue: [UUID: [EquivalencyContext: Bool]] = [:]
    }

    fileprivate var environmentComparisonCacheKey: [UUID: [EquivalencyContext: Bool]] {
        get { self[EnvironmentComparisonCacheKey.self] }
        set { self[EnvironmentComparisonCacheKey.self] = newValue }
    }

}

extension Environment {

    fileprivate struct Keybox: Hashable, CustomStringConvertible {

        let objectIdentifier: ObjectIdentifier
        let type: any EnvironmentKey.Type
        let isEquivalent: (Any?, Any?, EquivalencyContext) -> Bool

        init<EnvironmentKeyType: EnvironmentKey>(_ type: EnvironmentKeyType.Type) {
            objectIdentifier = ObjectIdentifier(type)
            self.type = type
            isEquivalent = {
                guard let lhs = $0 as? EnvironmentKeyType.Value, let rhs = $1 as? EnvironmentKeyType.Value else { return false }
                return type.isEquivalent(lhs: lhs, rhs: rhs, in: $2)
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

protocol InternalEnvironmentKey: EnvironmentKey {}

extension InternalEnvironmentKey {

    // Internal keys don't participate in equivalency, they always return as being equivalent.
    static func isEquivalent(lhs: Value, rhs: Value, in context: EquivalencyContext) -> Bool {
        true
    }
}


// FIXME: MOVE

final class CacheStorage: Sendable, CustomDebugStringConvertible {

    var name: String? = nil
    private var storage: [ObjectIdentifier: Any] = [:]

    subscript<KeyType>(key: KeyType.Type) -> KeyType.Value where KeyType: CacheKey {
        get {
            storage[ObjectIdentifier(key), default: KeyType.emptyValue] as! KeyType.Value
        }
        set {
            storage[ObjectIdentifier(key)] = newValue
        }
    }

    func clear<KeyType>(key: KeyType.Type) -> KeyType.Value? where KeyType: CacheKey {
        storage.removeValue(forKey: ObjectIdentifier(key)) as? KeyType.Value
    }

    var debugDescription: String {
        if let name {
            "CacheStorage (\(name))"
        } else {
            "CacheStorage"
        }
    }

}

public protocol CacheKey {
    associatedtype Value
    static var emptyValue: Self.Value { get }
}

extension Environment {

    struct CacheStorageEnvironmentKey: InternalEnvironmentKey {
        static var defaultValue = CacheStorage()
    }

    var cacheStorage: CacheStorage {
        get { self[internal: CacheStorageEnvironmentKey.self] }
        set { self[internal: CacheStorageEnvironmentKey.self] = newValue }
    }

}

extension ContextuallyEquivalent {

    fileprivate func isEquivalent(to other: (any ContextuallyEquivalent)?, in context: EquivalencyContext) -> Bool {
        isEquivalent(to: other as? Self, in: context)
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
