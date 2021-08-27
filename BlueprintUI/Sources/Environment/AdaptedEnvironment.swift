import CoreGraphics

/// Wraps an element tree with a modified environment.
///
/// By specifying environmental values with this element, all child elements nested
/// will automatically inherit those values automatically. Values can be changed
/// anywhere in a sub-tree by inserting another `AdaptedEnvironment` element.
public struct AdaptedEnvironment: Element {

    /// Takes in a mutable `Environment` which can be mutated to add or override values.
    public typealias Adapter = (inout Environment) -> Void

    var wrapped: Element
    var adapters: [Adapter]

    /// Wraps an element with an environment that is modified using the given
    /// configuration block.
    ///
    /// - Parameters:
    ///   - by: A block that will set environmental values.
    ///   - wrapping: The element to be wrapped.
    public init(
        by adapt: @escaping Adapter,
        wrapping wrapped: Element
    ) {
        if var adapter = wrapped as? AdaptedEnvironment {
            adapter.adapters.append(adapt)
            self = adapter
        } else {
            self.wrapped = wrapped
            adapters = [adapt]
        }
    }

    /// Wraps an element with an environment that is modified for a single key and value.
    /// - Parameters:
    ///   - key: The environment key to modify.
    ///   - value: The new environment value to cascade.
    ///   - wrapping: The element to be wrapped.
    public init<Key>(
        key: Key.Type,
        value: Key.Value,
        wrapping child: Element
    ) where Key: EnvironmentKey {
        self.init(by: { $0[key] = value }, wrapping: child)
    }

    /// Wraps an element with an environment that is modified for a single value.
    /// - Parameters:
    ///   - keyPath: The keypath of the environment value to modify.
    ///   - value: The new environment value to cascade.
    ///   - wrapping: The element to be wrapped.
    public init<Value>(
        keyPath: WritableKeyPath<Environment, Value>,
        value: Value,
        wrapping child: Element
    ) {
        self.init(by: { $0[keyPath: keyPath] = value }, wrapping: child)
    }

    public var content: ElementContent {
        ElementContent(
            child: wrapped,
            environment: { env in
                for adapter in self.adapters.reversed() {
                    adapter(&env)
                }
            }
        )
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
}


extension Element {

    /// Wraps this element in an `AdaptedEnvironment` with the given environment key and value.
    public func adaptedEnvironment<Key>(key: Key.Type, value: Key.Value) -> Element where Key: EnvironmentKey {
        AdaptedEnvironment(key: key, value: value, wrapping: self)
    }

    /// Wraps this element in an `AdaptedEnvironment` with the given keypath and value.
    public func adaptedEnvironment<Value>(keyPath: WritableKeyPath<Environment, Value>, value: Value) -> Element {
        AdaptedEnvironment(keyPath: keyPath, value: value, wrapping: self)
    }

    /// Wraps this element in an `AdaptedEnvironment` with the given configuration block.
    public func adaptedEnvironment(by environmentAdapter: @escaping (inout Environment) -> Void) -> Element {
        AdaptedEnvironment(by: environmentAdapter, wrapping: self)
    }
}
