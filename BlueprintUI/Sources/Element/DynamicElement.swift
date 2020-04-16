import CoreGraphics

/// An element that dynamically builds its content based on the environment.
///
/// Similar in purpose to `ProxyElement`, but the contents may change depending on the `Environment`.
///
/// - seealso: ProxyElement
public protocol DynamicElement: Element {

    /// Return the contents of this element in the given environment.
    func elementRepresentation(in environment: Environment) -> Element
}

extension DynamicElement {
    public var content: ElementContent {
        return ElementContent(build: self.elementRepresentation(in:))
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }
}
