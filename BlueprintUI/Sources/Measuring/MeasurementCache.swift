import UIKit


public final class MeasurementCache {

    /// Provides access to a view in the provided block.
    public func access<Value: AnyObject, Result>(
        type: Value.Type,
        perform: (Value) -> Result,
        create: () -> Value
    ) -> Result {
        perform(cachedValue(create))
    }

    private func cachedValue<Value: AnyObject>(_ create: () -> Value) -> Value {

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

    private var views: [Key: AnyObject] = [:]

    private struct Key: Hashable {
        let elementType: ObjectIdentifier
    }
}
