import UIKit

/// Changes the opacity of the wrapped element.
public struct Opacity: Element {

    /// The content element whose opacity is being affected.
    public var wrappedElement: Element

    /// The opacity of the wrapped element.
    public var opacity: CGFloat

    /// Initializes an `Opacity` with the given content element and opacity.
    ///
    /// - parameters:
    ///   - opacity: The opacity to be applied to the wrapped element.
    ///   - wrapping: The content element to be made transparent.
    public init(
        opacity: CGFloat,
        wrapping wrappedElement: Element
    ) {
        self.opacity = opacity
        self.wrappedElement = wrappedElement
    }

    public var content: ElementContent {
        return ElementContent(child: wrappedElement, layout: Layout(opacity: opacity))
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }

    private struct Layout: SingleChildLayout {
        var opacity: CGFloat

        func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {
            return child.measure(in: constraint)
        }

        func layout(size: CGSize, child: Measurable) -> LayoutAttributes {
            var attributes = LayoutAttributes(size: size)
            attributes.alpha = opacity
            return attributes
        }
    }
}

public extension Element {
    /// Wraps the element in an `Opacity` element with the provided opacity.
    ///
    /// - parameters:
    ///   - opacity: The opacity to be applied.
    ///
    func opacity(_ opacity: CGFloat) -> Opacity {
        return Opacity(
            opacity: opacity,
            wrapping: self
        )
    }
}
