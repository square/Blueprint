import Foundation

public protocol EnvironmentKey {
    associatedtype Value

    static var defaultValue: Self.Value { get }
}

public struct Environment {
    public init() { }

    var values: [ObjectIdentifier: Any] = [:]

    public subscript<K>(key: K.Type) -> K.Value where K: EnvironmentKey {
        get {
            let objectId = ObjectIdentifier(key)

            if let value = values[objectId] as? K.Value {
                return value
            }

            return key.defaultValue
        }
        set {
            values[ObjectIdentifier(key)] = newValue
        }
    }
}
