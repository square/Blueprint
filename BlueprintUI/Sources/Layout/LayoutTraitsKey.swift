import Foundation

public protocol LayoutTraitsKey {
    associatedtype Value

    static var defaultValue: Value { get }
}

public enum LegacyLayoutTraitsKey<LayoutType: LegacyLayout>: LayoutTraitsKey {
    public typealias Value = LayoutType.Traits

    public static var defaultValue: Value {
        LayoutType.defaultTraits
    }
}

struct LayoutTraits {

    static let empty = Self()

    private var values: [ObjectIdentifier: Any] = [:]

    /// Gets or sets an environment value by its key.
    subscript<Key>(key: Key.Type) -> Key.Value where Key: LayoutTraitsKey {
        get {
            let objectId = ObjectIdentifier(key)

            if let value = values[objectId] {
                return value as! Key.Value
            }

            return key.defaultValue
        }
        set {
            values[ObjectIdentifier(key)] = newValue
        }
    }

    subscript<LayoutType: LegacyLayout>(legacyLayout legacyLayout: LayoutType.Type) -> LayoutType.Traits {
        get {
            self[LegacyLayoutTraitsKey<LayoutType>.self]
        }
        set {
            self[LegacyLayoutTraitsKey<LayoutType>.self] = newValue
        }
    }

    init() {}

    init<K: LayoutTraitsKey>(key: K.Type, value: K.Value) {
        self[key] = value
    }
}
