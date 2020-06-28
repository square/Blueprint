import Foundation

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

    private init() { }

    private var values: [ObjectIdentifier: Any] = [:]
    
    private var readNotifications : [ReadNotification] = []
    private var writeNotifications : [WriteNotification] = []
    
    struct ReadNotification {
        weak var observer : AnyObject?
        var callback : (EnvironmentKeyType) -> ()
    }

    struct WriteNotification {
        weak var observer : AnyObject?
        var callback : (EnvironmentKeyType) -> ()
    }
    
    /// Gets or sets an environment value by its key.
    public subscript<Key>(key: Key.Type) -> Key.Value where Key: EnvironmentKey {
        get {
            let keyType = EnvironmentKeyType(Key.self)
            let objectId = ObjectIdentifier(key)
            let existing = self.values[objectId] as! Key.Value?
            
            let value : Key.Value = existing ?? key.defaultValue
            
            self.readNotifications.forEach {
                $0.callback(keyType)
            }

            return value
        }
        set {
            let key = ObjectIdentifier(key)
            let existing = values[key] as! Key.Value?
            
            values[key] = newValue
            
            if Key.areValuesEqual(lhs: existing, rhs: newValue) == false {
                let keyType = EnvironmentKeyType(Key.self)
                
                self.writeNotifications.forEach {
                    $0.callback(keyType)
                }
            }
        }
    }
}
