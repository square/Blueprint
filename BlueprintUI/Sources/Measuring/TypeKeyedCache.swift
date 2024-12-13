import UIKit

/// A cache that uses the value's type as the key.
public final class TypeKeyedCache {

    private var views: [Key: AnyObject] = [:]

    // Intentionally internal. Not intended for public instantiation.
    init() {}

    // Returns the cached value for the Value type if it exists. If it doesn't
    // exist, it creates a new instance of Value, caches it, and returns it.
    //
    // - Parameter create: A closure that creates a new instance of Value. It
    // is only invoked when a cached value does not exist. The created value is
    // cached for future usage.
    public func value<Value: AnyObject>(_ create: () -> Value) -> Value {
        let key = Key(
            elementType: ObjectIdentifier(Value.self)
        )

        if let existing = views[key] {
            return existing as! Value
        } else {
            let new = create()
            views[key] = new
            return new
        }
    }

    private struct Key: Hashable {
        let elementType: ObjectIdentifier
    }
}
