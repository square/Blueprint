/// `GridRowChild` is a wrapper which allows an element to define its `GridRow.Width` and `key`.
/// This struct is particularly useful when working with a result builder initializer that uses `@ElementBuilder`.
/// By default, elements will be set to a nil key and `.proportional(1)` initializer.
/// The initializer will check every child to see if it can be type cast to a `GridRowChild`
/// and then pull out the given width and key and then apply those to the row.
public struct GridRowChild {
    public let element: Element
    public var width: GridRow.Width
    public let key: AnyHashable?

    /// Bundles a wrapped element with the layout information needed for a `GridRow`.
    /// - Parameters:
    ///   - wrappedElement: The element to wrap.
    ///   - key: A unique identifier for the child.
    ///   - width: The sizing for the element.
    public init(
        _ element: Element,
        key: AnyHashable? = nil,
        width: GridRow.Width
    ) {
        self.element = element
        self.key = key
        self.width = width
    }
}

extension Element {
    /// Wraps an element with a `GridRowChild` in order to provide meta information that a `GridRow` can aply to its layout.
    /// - Parameters:
    ///   - key: A unique identifier for the child.
    ///   - width: The sizing for the element.
    /// - Returns: `GridRowChild`
    public func gridRowChild(key: AnyHashable? = nil, width: GridRow.Width) -> GridRowChild {
        .init(self, key: key, width: width)
    }
}
