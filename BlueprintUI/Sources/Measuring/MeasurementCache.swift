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


extension Environment {

    private static let fallback = MeasurementCache()

    public internal(set) var elementMeasurer: MeasurementCache {
        get {
            if let inheritedElementMeasurer {
                return inheritedElementMeasurer
            } else {
                #if DEBUG
                do {
                    /// Set a breakpoint on this `throw` if you'd like to understand where this error is occurring.
                    ///
                    /// We throw a caught error so that program execution can continue, and folks can opt
                    /// in or out of stopping on the error.
                    throw MeasurementErrors.fallingBackToStaticCache
                } catch {

                    /// **Warning**: Blueprint is falling back to a static `MeasurementCache`,
                    /// which will result in prototype measurement values being retained for
                    /// the lifetime of the application, which can result in memory leaks.
                    ///
                    /// If you are seeing this error, ensure you're passing the Blueprint `Environment`
                    /// properly through your element hierarchies – you should almost _never_ be
                    /// passing an `.empty` environment to methods, and instead passing an inherited
                    /// environment which will be passed to you by callers or a parent view controller,
                    /// screen, or element.
                    ///
                    /// To learn more, see https://github.com/square/Blueprint/tree/main/Documentation/TODO.md.

                }
                #endif

                return Self.fallback
            }
        }

        set {
            self[ElementMeasurerKey.self] = newValue
        }
    }

    public enum MeasurementErrors: Error {
        case fallingBackToStaticCache
    }

    var inheritedElementMeasurer: MeasurementCache? {
        self[ElementMeasurerKey.self]
    }

    private enum ElementMeasurerKey: EnvironmentKey {
        static let defaultValue: MeasurementCache? = nil
    }
}
