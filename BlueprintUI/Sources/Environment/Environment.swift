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
public struct Environment: Equatable {

    /// A default "empty" environment, with no values overridden.
    /// Each key will return its default value.
    public static let empty = Environment()

    /// If the `Environment` contains any values.
    var isEmpty: Bool {
        values.isEmpty
    }

    private var values: [StorageKey: ValueBox] = [:]

    /// Gets or sets an environment value by its key.
    public subscript<KeyType: EnvironmentKey>(key: KeyType.Type) -> KeyType.Value {
        get {
            let storageKey = StorageKey(key)

            for reader in readSubscriptions {
                reader(storageKey)
            }

            if let value = values[storageKey] {
                return value.base as! KeyType.Value
            }
            return key.defaultValue
        }
        set {
            values[StorageKey(key)] = ValueBox(newValue)
        }
    }

    public func adapted<Key: EnvironmentKey>(key: Key.Type, value: Key.Value) -> Environment {
        var newThingy = self

        newThingy[key] = value

        return newThingy
    }

    public static func == (lhs: Environment, rhs: Environment) -> Bool {
        guard lhs.values.count == rhs.values.count else { return false }

        for (key, value) in lhs.values {
            if key.valuesEqual(value.base, rhs.values[key]?.base) == false {
                return false
            }
        }

        return true
    }

    func valuesEqual(to subset: Environment.ReadValues?) -> Bool {

        guard let subset = subset else { return true }

        for (key, value) in subset.values {

            let other = values[key]

            if value === values[key] {
                /// Short circuit: Identical container references, no need to compare anything else.
                continue
            } else if key.valuesEqual(value.base, other?.base) == false {
                return false
            }
        }

        return true
    }

    func subset(with keys: Set<StorageKey>) -> Environment.ReadValues {

        var subset = ReadValues()
        subset.values.reserveCapacity(keys.count)

        for key in keys {
            if let value = values[key] {
                subset.values[key] = value
            }
        }

        return subset
    }

    /// Callback for when an `EnvironmentKey` is read from the `Environment`.
    typealias OnDidRead = (StorageKey) -> Void

    /// When an `EnvironmentKey` is read from the `Environment`,
    /// the provided callback is invoked, allowing the caller to track what is being
    /// accessed in the environment. This is used by the measurement and layout
    /// phases of the render pass in order to determine if cached measurements
    /// and layouts can be reused.
    mutating func subscribeToReads(with callback: @escaping OnDidRead) {
        readSubscriptions.append(callback)
    }

    private var readSubscriptions: [OnDidRead] = []

    /// Returns a new `Environment` by merging the values from `self` and the
    /// provided environment; keeping values from the provided environment when there
    /// are key overlaps between the two environments.
    func merged(prioritizing other: Environment) -> Environment {
        var merged = self
        merged.values.merge(other.values) { $1 }
        return merged
    }
}

extension Environment {

    /// A subset of `Environment.value`s that can be used for matching a set of
    /// key-value pairs with other `Environment`s
    struct ReadValues {
        var values: [StorageKey: ValueBox] = [:]
    }

    /// Place values in the environment into a reference box, so that their storage is only allocated once
    /// even when placed into an environment subset for change tracking.
    final class ValueBox {
        let base: Any

        init(_ base: Any) {
            self.base = base
        }
    }

    struct StorageKey: Hashable {

        private let identifier: ObjectIdentifier

        private let isEqual: (Any?, Any?) -> Bool

        init<KeyType: EnvironmentKey>(_ key: KeyType.Type) {
            identifier = ObjectIdentifier(key)

            isEqual = KeyType.areValuesEqual
        }

        fileprivate func valuesEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
            isEqual(lhs, rhs)
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(identifier)
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.identifier == rhs.identifier
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

    private static var environmentKey = NSObject()
}

