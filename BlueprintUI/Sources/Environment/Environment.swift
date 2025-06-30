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

    private var values: [Keybox: Any] = [:]

    /// Gets or sets an environment value by its key.
    public subscript<Key>(key: Key.Type) -> Key.Value where Key: EnvironmentKey {
        get {
            let keybox = Keybox(key)

            if let value = values[keybox] {
                return value as! Key.Value
            }

            return key.defaultValue
        }
        set {
            values[Keybox(key)] = newValue
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
        // There are situations where the addition or removal of an environment value will not affect equivalency.
        // This is expressed by `someValue.isEquivalent(to: nil, context: .someContext)` – we'll keep track of
        // checked values to make sure that if we do this check, nil is always in the param, and not the callee.
        var checkedKeys: Set<Keybox> = []
        for (key, value) in values {
            checkedKeys.insert(key)
            guard key.isEquivalent(value, other.values[key], context) else { return false }
        }
        for (key, value) in other.values {
            guard !checkedKeys.contains(key) else { continue }
            guard key.isEquivalent(other.values[key], value, context) else { return false }
        }
        return true
    }

}

extension Environment {

    fileprivate struct Keybox: Hashable {

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
