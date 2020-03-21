import CoreGraphics

/// An element built out of other elements.
///
/// Similar in purpose to `ProxyElement`, but the contents may change depending on the `Environment`.
///
/// - seealso: ProxyElement
public protocol ComposedElement: Element {

    /// Return the contents of this element in the given environment.
    func elementRepresentation(in environment: Environment) -> Element
}

extension ComposedElement {
    public var content: ElementContent {
        return ElementContent(build: self.elementRepresentation(in:))
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }
}
