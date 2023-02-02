import CoreGraphics

/// `UserInteractionEnabled` conditionally enables user interaction of its wrapped element.
///
/// - Note: When user interaction is disabled, any elements within the wrapped element will become non-interactive.
public struct UserInteractionEnabled: Element {
    public var isEnabled: Bool
    public var wrappedElement: Element

    public init(_ isEnabled: Bool, wrapping element: Element) {
        self.isEnabled = isEnabled
        wrappedElement = element
    }

    public var content: ElementContent {
        ElementContent(child: wrappedElement, layout: Layout(isEnabled: isEnabled))
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }

    private struct Layout: SingleChildLayout {
        var isEnabled: Bool

        func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {
            child.measure(in: constraint)
        }

        func layout(size: CGSize, child: Measurable) -> LayoutAttributes {
            var attributes = LayoutAttributes(size: size)
            attributes.isUserInteractionEnabled = isEnabled
            return attributes
        }

        func sizeThatFits(proposal: SizeConstraint, subview: LayoutSubview, cache: inout Cache) -> CGSize {
            subview.sizeThatFits(proposal)
        }

        func placeSubview(in bounds: CGRect, proposal: SizeConstraint, subview: LayoutSubview, cache: inout ()) {
            subview.attributes.isUserInteractionEnabled = isEnabled
        }

        func layout(in context: StrictLayoutContext, child: StrictLayoutable) -> StrictLayoutAttributes {
            var attributes = StrictLayoutAttributes(
                size: child.layout(in: context.proposedSize),
                childPositions: [.zero]
            )
            attributes.isUserInteractionEnabled = isEnabled
            return attributes
        }
    }
}

extension Element {
    /// Conditionally enable user interaction of the wrapped element.
    ///
    /// - Note: When user interaction is disabled, any elements within the wrapped element will become non-interactive.
    public func userInteractionEnabled(_ enabled: Bool = true) -> UserInteractionEnabled {
        UserInteractionEnabled(enabled, wrapping: self)
    }
}
