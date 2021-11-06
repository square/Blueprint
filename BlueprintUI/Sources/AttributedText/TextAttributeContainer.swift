import UIKit

public struct TextAttributeContainer {
    public static let empty = Self()

    internal var storage: [NSAttributedString.Key: Any]

    /// Private empty initializer to make the `empty` environment explicit.
    private init() {
        storage = [:]
    }

    /// Get or set for the given `AttributedTextKey`.
    public subscript<Key>(key: Key.Type) -> Key.Value? where Key: AttributedTextKey {
        get {
            if let value = storage[key.name] as? Key.Value {
                return value
            } else {
                return nil
            }
        }
        set {
            storage[key.name] = newValue
        }
    }
}

