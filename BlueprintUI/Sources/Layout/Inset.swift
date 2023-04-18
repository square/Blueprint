import UIKit

/// Insets a content element within a layout.
///
/// Commonly used to add padding around another element when displayed within a container.
///
public struct Inset: Element {

    /// The wrapped element to be inset.
    public var wrappedElement: Element

    /// The amount to inset the content element.
    public var top: CGFloat
    public var bottom: CGFloat
    public var left: CGFloat
    public var right: CGFloat

    public init(
        top: CGFloat = 0.0,
        bottom: CGFloat = 0.0,
        left: CGFloat = 0.0,
        right: CGFloat = 0.0,
        wrapping element: Element
    ) {
        wrappedElement = element
        self.top = top
        self.bottom = bottom
        self.left = left
        self.right = right
    }

    public init(uniformInset: CGFloat, wrapping element: Element) {
        wrappedElement = element
        top = uniformInset
        bottom = uniformInset
        left = uniformInset
        right = uniformInset
    }

    public init(insets: UIEdgeInsets, wrapping element: Element) {
        wrappedElement = element
        top = insets.top
        bottom = insets.bottom
        left = insets.left
        right = insets.right
    }

    public init(sideInsets: CGFloat, wrapping element: Element) {
        self.init(
            insets: UIEdgeInsets(
                top: 0.0,
                left: sideInsets,
                bottom: 0.0,
                right: sideInsets
            ),
            wrapping: element
        )
    }

    public init(vertical: CGFloat, wrapping element: Element) {
        self.init(
            top: vertical,
            bottom: vertical,
            wrapping: element
        )
    }

    public var content: ElementContent {
        ElementContent(
            child: wrappedElement,
            layout: Layout(
                top: top,
                bottom: bottom,
                left: left,
                right: right
            )
        )
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
}


extension Element {

    /// Insets the element by the given amount on each side.
    public func inset(
        top: CGFloat = 0.0,
        bottom: CGFloat = 0.0,
        left: CGFloat = 0.0,
        right: CGFloat = 0.0
    ) -> Inset {
        Inset(
            top: top,
            bottom: bottom,
            left: left,
            right: right,
            wrapping: self
        )
    }

    /// Insets the element by the given amount on each side.
    public func inset(by edgeInsets: UIEdgeInsets) -> Inset {
        Inset(insets: edgeInsets, wrapping: self)
    }

    /// Insets the element by the given amount on each side.
    public func inset(uniform: CGFloat) -> Inset {
        Inset(uniformInset: uniform, wrapping: self)
    }

    /// Insets the element by the given amount on each side.
    public func inset(
        horizontal: CGFloat = 0.0,
        vertical: CGFloat = 0.0
    ) -> Inset {
        Inset(
            top: vertical,
            bottom: vertical,
            left: horizontal,
            right: horizontal,
            wrapping: self
        )
    }
}


extension Inset {

    fileprivate struct Layout: SingleChildLayout {

        var top: CGFloat
        var bottom: CGFloat
        var left: CGFloat
        var right: CGFloat

        func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {
            let insetConstraint = constraint.inset(
                width: left + right,
                height: top + bottom
            )

            var size = child.measure(in: insetConstraint)

            size.width += left + right
            size.height += top + bottom

            return size
        }

        func layout(size: CGSize, child: Measurable) -> LayoutAttributes {
            var frame = CGRect(origin: .zero, size: size)
            frame.origin.x += left
            frame.origin.y += top
            frame.size.width -= left + right
            frame.size.height -= top + bottom
            return LayoutAttributes(frame: frame)
        }

        func sizeThatFits(
            proposal: SizeConstraint,
            subelement: Subelement,
            environment: Environment,
            cache: inout ()
        ) -> CGSize {
            let insetProposal = proposal.inset(by: edgeInsets)
            let childSize = subelement.sizeThatFits(insetProposal)
            return childSize + CGSize(width: left + right, height: top + bottom)
        }

        func placeSubelement(
            in size: CGSize,
            subelement: Subelement,
            environment: Environment,
            cache: inout ()
        ) {
            let insetSize = size.inset(by: edgeInsets)

            subelement.place(
                at: CGPoint(x: edgeInsets.left, y: edgeInsets.top),
                anchor: .topLeading,
                size: insetSize
            )
        }

        private var edgeInsets: UIEdgeInsets {
            .init(top: top, left: left, bottom: bottom, right: right)
        }
    }
}
