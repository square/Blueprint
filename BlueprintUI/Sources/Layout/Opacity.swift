import UIKit

/// Changes the opacity of the wrapped element.
public struct Opacity<Wrapped:Element>: Element {

    /// The content element whose opacity is being affected.
    public var wrapped: Wrapped

    /// The opacity of the wrapped element.
    public var opacity: CGFloat

    /// Initializes an `Opacity` with the given content element and opacity.
    ///
    /// - parameters:
    ///   - opacity: The opacity to be applied to the wrapped element.
    ///   - wrapping: The content element to be made transparent.
    public init(
        opacity: CGFloat,
        wrapping wrapped: Wrapped
    ) {
        self.opacity = opacity
        self.wrapped = wrapped
    }

    public var content: ElementContent {
        return ElementContent(child: wrapped, layout: Layout(opacity: opacity))
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        return nil
    }

    private struct Layout: SingleChildLayout {
        
        var opacity: CGFloat

        func measure(
            child: Measurable,
            in constraint : SizeConstraint,
            with context: LayoutContext
        ) -> CGSize
        {
            child.measure(in: constraint, with: context)
        }

        func layout(
            child: Measurable,
            in size : CGSize,
            with context : LayoutContext
        ) -> LayoutAttributes
        {
            var attributes = LayoutAttributes(size: size)
            attributes.alpha = opacity
            
            return attributes
        }
    }
}


extension Opacity:Equatable where Wrapped:Equatable {}
extension Opacity:AnyComparableElement where Wrapped:Equatable {}
extension Opacity:ComparableElement where Wrapped:Equatable {}


public extension Element {
    /// Wraps the element in an `Opacity` element with the provided opacity.
    ///
    /// - parameters:
    ///   - opacity: The opacity to be applied.
    ///
    func opacity(_ opacity: CGFloat) -> Opacity<Self> {
        return Opacity(
            opacity: opacity,
            wrapping: self
        )
    }
}
