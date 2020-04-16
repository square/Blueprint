import Foundation

public protocol EnvironmentKey {
    associatedtype Value

    static var defaultValue: Self.Value { get }
}

public struct Environment {
    public static let empty = Environment()

    private init() { }

    private var values: [ObjectIdentifier: Any] = [:]

    public subscript<K>(key: K.Type) -> K.Value where K: EnvironmentKey {
        get {
            let objectId = ObjectIdentifier(key)

            if let value = values[objectId] {
                return value as! K.Value
            }

            return key.defaultValue
        }
        set {
            values[ObjectIdentifier(key)] = newValue
        }
    }
}
