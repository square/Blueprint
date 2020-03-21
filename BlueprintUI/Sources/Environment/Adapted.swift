import CoreGraphics

/// Wraps an element tree with a modified environment.
///
/// By specifying environmental values with this element, all child elements nested
/// will automatically inherit those values automatically. Values can be changed
/// anywhere in a sub-tree by inserting another `Adapted` element.
public struct Adapted: Element {
    var wrappedElement: Element
    var environmentAdapter: (inout Environment) -> Void

    /// Wraps an element with an environment that is modified using the given
    /// configuration block.
    /// - Parameters:
    ///   - by: A block that will set environmental values.
    ///   - wrapping: The element to be wrapped.
    public init(
        by environmentAdapter: @escaping (inout Environment) -> Void,
        wrapping wrappedElement: Element)
    {
        self.wrappedElement = wrappedElement
        self.environmentAdapter = environmentAdapter
    }

    /// Wraps an element with an environment that is modified for a single key and value.
    /// - Parameters:
    ///   - key: The environment key to modify.
    ///   - value: The new environment value to cascade.
    ///   - wrapping: The element to be wrapped.
    public init<K>(key: K.Type, value: K.Value, wrapping child: Element) where K: EnvironmentKey {
        self.init(by: { $0[key] = value }, wrapping: child)
    }

    public var content: ElementContent {
        return ElementContent(child: wrappedElement, environment: environmentAdapter)
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }
}
