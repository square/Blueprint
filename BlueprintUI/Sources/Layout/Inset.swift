import UIKit

/// Insets a content element within a layout.
///
/// Commonly used to add padding around another element when displayed within a
/// container.
public struct Inset: Element {

    /// The wrapped element to be inset.
    public var wrappedElement: Element

    /// The amount to inset the content element.
    public var top: CGFloat
    public var bottom: CGFloat
    public var left: CGFloat
    public var right: CGFloat
    
    public init(top: CGFloat = 0.0, bottom: CGFloat = 0.0, left: CGFloat = 0.0, right: CGFloat = 0.0, wrapping element: Element) {
        self.wrappedElement = element
        self.top = top
        self.bottom = bottom
        self.left = left
        self.right = right
    }
    
    public init(uniformInset: CGFloat, wrapping element: Element) {
        self.wrappedElement = element
        self.top = uniformInset
        self.bottom = uniformInset
        self.left = uniformInset
        self.right = uniformInset
    }
    
    public init(insets: UIEdgeInsets, wrapping element: Element) {
        self.wrappedElement = element
        self.top = insets.top
        self.bottom = insets.bottom
        self.left = insets.left
        self.right = insets.right
    }
    
    public init(sideInsets: CGFloat, wrapping element: Element) {
        self.init(
            insets: UIEdgeInsets(
                top: 0.0,
                left: sideInsets,
                bottom: 0.0,
                right: sideInsets),
            wrapping: element)
    }
    
    public init(vertical: CGFloat, wrapping element: Element) {
        self.init(
            top: vertical,
            bottom: vertical,
            wrapping: element)
    }

    public var content: ElementContent {
        return ElementContent(
            child: wrappedElement,
            layout: Layout(
                top: top,
                bottom: bottom,
                left: left,
                right: right))
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }
    
}


extension Inset {

    fileprivate struct Layout: SingleChildLayout {
        
        var top: CGFloat
        var bottom: CGFloat
        var left: CGFloat
        var right: CGFloat

        func layout(in constraint: SizeConstraint, child: MeasurableChild) -> SingleChildLayoutResult {
            SingleChildLayoutResult(
                size: {
                    let insetConstraint = constraint.inset(
                        width: left + right,
                        height: top + bottom
                    )

                    var size = child.size(in: insetConstraint)

                    size.width += left + right
                    size.height += top + bottom

                    return size
                },                
                layoutAttributes: {
                    var frame = CGRect(origin: .zero, size: $0)
                    frame.origin.x += left
                    frame.origin.y += top
                    frame.size.width -= left + right
                    frame.size.height -= top + bottom
                    
                    return LayoutAttributes(frame: frame)
                }
            )
        }
    }

}
