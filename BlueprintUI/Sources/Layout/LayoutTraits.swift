import Foundation

/// A heterogeneous container of traits associated with a subelement being laid out.
///
/// Generally, layout implementations will not need to use this type directly. However, elements
/// that apply multiple traits to each subelement will use this type to store the traits, and
/// calling ``ElementContent/Builder/add(traits:key:element:)-3rxz0`` when creating the
/// ``ElementContent``.
///
/// Layout implementations may access subelements' traits during layout using the
/// ``LayoutSubelement/subscript(key:)`` subscript. For more information, see ``LayoutTraitsKey``.
///
public struct LayoutTraits {

    /// An empty set of traits.
    public static let empty = Self()

    private var values: [ObjectIdentifier: Any] = [:]

    private init() {}

    /// Creates a set of traits containing the specified key and value.
    public init<K: LayoutTraitsKey>(key: K.Type, value: K.Value) {
        self[key] = value
    }

    /// Gets or sets a trait value by its key.
    public subscript<Key>(key: Key.Type) -> Key.Value where Key: LayoutTraitsKey {
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

    subscript<LayoutType: SingleTraitLayout>(layout layout: LayoutType.Type) -> LayoutType.Traits {
        get {
            self[SingleTraitLayoutTraitsKey<LayoutType>.self]
        }
        set {
            self[SingleTraitLayoutTraitsKey<LayoutType>.self] = newValue
        }
    }

    /// Returns a copy of this set of traits with the specified key and value set.
    public func setting<Key: LayoutTraitsKey>(key: Key.Type, to value: Key.Value) -> Self {
        var copy = self
        copy[key] = value
        return copy
    }
}
