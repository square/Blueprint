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

        func sizeThatFits(proposal: ProposedViewSize, subview: LayoutSubview) -> CGSize {
            subview.sizeThatFits(proposal)
        }

        func placeSubview(in bounds: CGRect, proposal: ProposedViewSize, subview: LayoutSubview) {
            subview.attributes.isUserInteractionEnabled = isEnabled
        }
    }
}

struct SPAttributes {

    /// Corresponds to `UIView.layer.transform`.
    public var transform: CATransform3D

    /// Corresponds to `UIView.alpha`.
    public var alpha: CGFloat

    /// Corresponds to `UIView.isUserInteractionEnabled`.
    public var isUserInteractionEnabled: Bool

    /// Corresponds to `UIView.isHidden`.
    public var isHidden: Bool

    internal init(
        transform: CATransform3D = CATransform3DIdentity,
        alpha: CGFloat = 1,
        isUserInteractionEnabled: Bool = true,
        isHidden: Bool = false
    ) {
        self.transform = transform
        self.alpha = alpha
        self.isUserInteractionEnabled = isUserInteractionEnabled
        self.isHidden = isHidden
    }
}

protocol AttributeModifier {
    func attributes() -> SPAttributes
}

extension Element {
    /// Conditionally enable user interaction of the wrapped element.
    ///
    /// - Note: When user interaction is disabled, any elements within the wrapped element will become non-interactive.
    public func userInteractionEnabled(_ enabled: Bool = true) -> UserInteractionEnabled {
        UserInteractionEnabled(enabled, wrapping: self)
    }
}
