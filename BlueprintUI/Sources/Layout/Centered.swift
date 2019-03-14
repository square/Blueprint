/// Centers a content element within itself.
///
/// The size of the content element is determined by calling `measure(in:)` on
/// the content element – even if that size is larger than the wrapping `Centered`
/// element.
///
public struct Centered: Element {

    /// The content element to be centered.
    public var wrappedElement: Element

    /// Initializes a `Centered` element with the given content element.
    public init(_ wrappedElement: Element) {
        self.wrappedElement = wrappedElement
    }

    public var content: ElementContent {
        return ElementContent(child: wrappedElement, layout: Layout())
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }
}

extension Centered {
    fileprivate struct Layout: SingleChildLayout {

        func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {
            return child.measure(in: constraint)
        }

        func layout(size: CGSize, child: Measurable) -> LayoutAttributes {
            var childAttributes = LayoutAttributes()
            childAttributes.bounds.size = child.measure(in: SizeConstraint(size))
            childAttributes.center.x = size.width/2.0
            childAttributes.center.y = size.height/2.0
            return childAttributes
        }

    }
}
