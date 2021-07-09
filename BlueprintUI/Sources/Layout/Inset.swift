import UIKit

/// Insets a content element within a layout.
///
/// Commonly used to add padding around another element when displayed within a container.
///
public struct Inset<Wrapped:Element> : Element {

    /// The wrapped element to be inset.
    public var wrapped: Wrapped

    /// The amount to inset the content element.
    public var top: CGFloat
    public var bottom: CGFloat
    public var left: CGFloat
    public var right: CGFloat
    
    public init(top: CGFloat = 0.0, bottom: CGFloat = 0.0, left: CGFloat = 0.0, right: CGFloat = 0.0, wrapping element: Wrapped) {
        self.wrapped = element
        self.top = top
        self.bottom = bottom
        self.left = left
        self.right = right
    }
    
    public init(uniformInset: CGFloat, wrapping element: Wrapped) {
        self.wrapped = element
        self.top = uniformInset
        self.bottom = uniformInset
        self.left = uniformInset
        self.right = uniformInset
    }
    
    public init(insets: UIEdgeInsets, wrapping element: Wrapped) {
        self.wrapped = element
        self.top = insets.top
        self.bottom = insets.bottom
        self.left = insets.left
        self.right = insets.right
    }
    
    public init(sideInsets: CGFloat, wrapping element: Wrapped) {
        self.init(
            insets: UIEdgeInsets(
                top: 0.0,
                left: sideInsets,
                bottom: 0.0,
                right: sideInsets),
            wrapping: element
        )
    }
    
    public init(vertical: CGFloat, wrapping element: Wrapped) {
        self.init(
            top: vertical,
            bottom: vertical,
            wrapping: element
        )
    }

    public var content: ElementContent {
        return ElementContent(
            child: wrapped,
            layout: Layout(
                top: top,
                bottom: bottom,
                left: left,
                right: right
            )
        )
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        return nil
    }
}


public extension Element {
    
    /// Insets the element by the given amount on each side.
    func inset(
        top: CGFloat = 0.0,
        bottom: CGFloat = 0.0,
        left: CGFloat = 0.0,
        right: CGFloat = 0.0
    ) -> Inset<Self>
    {
        Inset(
            top: top,
            bottom: bottom,
            left: left,
            right: right,
            wrapping: self
        )
    }
    
    /// Insets the element by the given amount on each side.
    func inset(by edgeInsets : UIEdgeInsets) -> Inset<Self> {
        Inset(insets: edgeInsets, wrapping: self)
    }
    
    /// Insets the element by the given amount on each side.
    func inset(uniform : CGFloat) -> Inset<Self> {
        Inset(uniformInset: uniform, wrapping: self)
    }
    
    /// Insets the element by the given amount on each side.
    func inset(
        horizontal : CGFloat = 0.0,
        vertical : CGFloat = 0.0
    ) -> Inset<Self>
    {
        Inset(
            top: vertical,
            bottom: vertical,
            left: horizontal,
            right: horizontal,
            wrapping: self
        )
    }
}


extension Inset:Equatable where Wrapped:Equatable {}
extension Inset:AnyComparableElement where Wrapped:Equatable {}
extension Inset:ComparableElement where Wrapped:Equatable {}


extension Inset {

    fileprivate struct Layout: SingleChildLayout {

        var top: CGFloat
        var bottom: CGFloat
        var left: CGFloat
        var right: CGFloat

        func measure(
            child: Measurable,
            in constraint : SizeConstraint,
            with context: LayoutContext
        ) -> CGSize
        {
            let insetConstraint = constraint.inset(
                width: left + right,
                height: top + bottom
            )

            var size = child.measure(in: insetConstraint, with: context)

            size.width += left + right
            size.height += top + bottom

            return size
        }

        func layout(
            child: Measurable,
            in size : CGSize,
            with context : LayoutContext
        ) -> LayoutAttributes
        {
            var frame = CGRect(origin: .zero, size: size)
            frame.origin.x += left
            frame.origin.y += top
            frame.size.width -= left + right
            frame.size.height -= top + bottom
            
            return LayoutAttributes(frame: frame)
        }
    }
}
