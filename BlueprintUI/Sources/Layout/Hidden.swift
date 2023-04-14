import CoreGraphics

/// `Hidden` conditionally hides its wrapped element.
///
/// - Note: When an element is hidden, any elements within the wrapped element will be hidden.
public struct Hidden: Element {
    public var isHidden: Bool
    public var wrappedElement: Element

    public init(_ isHidden: Bool = true, wrapping element: Element) {
        self.isHidden = isHidden
        wrappedElement = element
    }

    public var content: ElementContent {
        ElementContent(child: wrappedElement, layout: Layout(isHidden: isHidden))
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }

    private struct Layout: SingleChildLayout {
        var isHidden: Bool

        func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {
            child.measure(in: constraint)
        }

        func layout(size: CGSize, child: Measurable) -> LayoutAttributes {
            var attributes = LayoutAttributes(size: size)
            attributes.isHidden = isHidden
            return attributes
        }

        func sizeThatFits(
            proposal: SizeConstraint,
            subelement: Subelement,
            environment: Environment,
            cache: inout Cache
        ) -> CGSize {
            subelement.sizeThatFits(proposal)
        }

        func placeSubelement(
            in size: CGSize,
            subelement: Subelement,
            environment: Environment,
            cache: inout ()
        ) {
            subelement.attributes.isHidden = isHidden
        }
    }
}

extension Element {
    /// Conditionally hide the wrapped element.
    ///
    /// Hidden elements still participate in layout. Hiding sets the `UIView.isHidden` property of the nearest backing view.
    ///
    /// - Note: When an element is hidden, any elements within the wrapped element will be hidden.
    public func hidden(_ hidden: Bool = true) -> Hidden {
        Hidden(hidden, wrapping: self)
    }
}
