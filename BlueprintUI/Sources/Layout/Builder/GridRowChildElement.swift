/// `GridRowChildElement` is a wrapper which allows an element to define its `GridRow.Width` and `key`.
/// This struct is particularly useful when working with result builder initializer which uses `@Builder<Element>`.
/// By default, elements will be set to a nil key and `.proportional(1)` initializer.
/// The initializer will check every child to see if it can be type cast to a `GridRowChildElement`
/// and then pull of the given width and key and then apply those to the row.
public struct GridRowChildElement: ProxyElement {
    private let wrappedElement: Element
    public var width: GridRow.Width
    public let key: AnyHashable?
    
    /// Bundles a wrapped element with the layout information needed for a `GridRow`.
    /// - Parameters:
    ///   - wrappedElement: The element to wrap.
    ///   - key: A unique identifier for the child.
    ///   - width: The sizing for the element.
    public init(
        _ wrappedElement: Element,
        key: AnyHashable? = nil,
        width: GridRow.Width
    ) {
        self.wrappedElement = wrappedElement
        self.key = key
        self.width = width
    }
    
    // Simply wraps the given element.
    public var elementRepresentation: Element { wrappedElement }
}

extension Element {
    /// Wraps an element with a `GridRowChildElement` in order to provide meta information that a `GridRow` can aply to its layout.
    /// - Parameters:
    ///   - key: A unique identifier for the child.
    ///   - width: The sizing for the element.
    /// - Returns: `GridRowChildElement`
    public func gridRowChild(key: AnyHashable? = nil, width: GridRow.Width) -> GridRowChildElement {
        .init(self, key: key, width: width)
    }
}
