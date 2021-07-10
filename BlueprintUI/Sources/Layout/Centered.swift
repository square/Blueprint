/// Centers a content element within itself.
///
/// The size of the content element is determined by calling `measure(in:)` on
/// the content element – even if that size is larger than the wrapping `Centered`
/// element.
///
public struct Centered<Wrapped:Element> : ProxyElement {

    /// The content element to be centered.
    public var wrapped: Wrapped

    /// Initializes a `Centered` element with the given content element.
    public init(_ wrapped: Wrapped) {
        self.wrapped = wrapped
    }

    public var elementRepresentation: Element {
        Aligned(
            vertically: .center,
            horizontally: .center,
            wrapping: wrapped
        )
    }
}


extension Centered:Equatable where Wrapped:Equatable {}
extension Centered:AnyComparableElement where Wrapped:Equatable {}
extension Centered:ComparableElement where Wrapped:Equatable {}


public extension Element {
    
    /// Wraps the element in a `Centered` element to center it within its parent.
    func centered() -> Centered<Self> {
        Centered(self)
    }
}
