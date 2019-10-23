/// Centers a content element within itself.
///
/// The size of the content element is determined by calling `measure(in:)` on
/// the content element – even if that size is larger than the wrapping `Centered`
/// element.
///
public struct Centered: ProxyElement {

    /// The content element to be centered.
    public var wrappedElement: Element

    /// Initializes a `Centered` element with the given content element.
    public init(_ wrappedElement: Element) {
        self.wrappedElement = wrappedElement
    }

    public var elementRepresentation: Element {
        return Aligned(vertically: .center, horizontally: .center, wrapping: wrappedElement)
    }
}
