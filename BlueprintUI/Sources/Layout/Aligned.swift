import UIKit

/// Aligns a content element within itself. The vertical and horizontal alignment may be set independently.
///
/// When using alignment mode `.fill`, the content is scaled to the width or height of the `Aligned` element.
///
/// For other modes, the size of the content element is determined by calling `measure(in:)`
/// on the content element – even if that size is larger than the wrapping element.
///
public struct Aligned: Element {
    /// The possible vertical alignment values.
    public enum VerticalAlignment {
        /// Aligns the content to the top edge of the containing element.
        case top
        /// Centers the content vertically.
        case center
        /// Aligns the content to the bottom edge of the containing element.
        case bottom
        /// The content fills the full vertical height of the containing element.
        case fill
    }

    /// The possible horizontal alignment values.
    public enum HorizontalAlignment {
        /// Aligns the content to the leading edge of the containing element.
        /// In left-to-right languages, this is the left edge.
        case leading
        /// Centers the content horizontally.
        case center
        /// Aligns the content to the trailing edge of the containing element.
        /// In left-to-right languages, this is the right edge.
        case trailing
        /// The content fills the full horizontal width of the containing element.
        case fill
    }

    /// The content element to be aligned.
    public var wrappedElement: Element
    /// The vertical alignment.
    public var verticalAlignment: VerticalAlignment
    /// The horizontal alignment.
    public var horizontalAlignment: HorizontalAlignment

    /// Initializes an `Aligned` with the given content element and alignments.
    ///
    /// - parameters:
    ///   - vertically: The vertical alignment. Defaults to centered.
    ///   - horizontally: The horizontal alignment. Defaults to centered.
    ///   - wrapping: The content element to be aligned.
    public init(
        vertically verticalAlignment: VerticalAlignment = .center,
        horizontally horizontalAlignment: HorizontalAlignment = .center,
        wrapping wrappedElement: Element
    ) {
        self.verticalAlignment = verticalAlignment
        self.horizontalAlignment = horizontalAlignment
        self.wrappedElement = wrappedElement
    }

    public var content: ElementContent {
        let layout = Layout(verticalAlignment: verticalAlignment, horizontalAlignment: horizontalAlignment)
        return ElementContent(child: wrappedElement, layout: layout)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }

    private struct Layout: SingleChildLayout {
        var verticalAlignment: VerticalAlignment
        var horizontalAlignment: HorizontalAlignment

        func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {
            child.measure(in: constraint)
        }

        func layout(size: CGSize, child: Measurable) -> LayoutAttributes {

            let measurement = child.measure(in: SizeConstraint(size))

            let constrainedMeasurement = CGSize(
                width: min(size.width, measurement.width),
                height: min(size.height, measurement.height)
            )

            var attributes = LayoutAttributes(
                size: constrainedMeasurement
            )

            switch verticalAlignment {
            case .top:
                attributes.frame.origin.y = 0
            case .center:
                attributes.frame.origin.y = (size.height - constrainedMeasurement.height) / 2.0
            case .bottom:
                attributes.frame.origin.y = size.height - constrainedMeasurement.height
            case .fill:
                attributes.frame.origin.y = 0
                attributes.frame.size.height = size.height
            }

            switch horizontalAlignment {
            case .leading:
                attributes.frame.origin.x = 0
            case .center:
                attributes.frame.origin.x = (size.width - constrainedMeasurement.width) / 2.0
            case .trailing:
                attributes.frame.origin.x = size.width - constrainedMeasurement.width
            case .fill:
                attributes.frame.origin.x = 0
                attributes.frame.size.width = size.width
            }

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
            let x: CGFloat
            let y: CGFloat

            let subelementSize = subelement
                .sizeThatFits(SizeConstraint(size))
                .upperBounded(by: size)

            let width: CGFloat
            let height: CGFloat

            switch horizontalAlignment {
            case .leading:
                x = 0
                width = subelementSize.width
            case .center:
                x = 0.5
                width = subelementSize.width
            case .trailing:
                x = 1
                width = subelementSize.width
            case .fill:
                x = 0
                width = size.width
            }

            switch verticalAlignment {
            case .top:
                y = 0
                height = subelementSize.height
            case .center:
                y = 0.5
                height = subelementSize.height
            case .bottom:
                y = 1
                height = subelementSize.height
            case .fill:
                y = 0
                height = size.height
            }

            let position = CGPoint(x: x * size.width, y: y * size.height)

            subelement.place(
                at: position,
                anchor: UnitPoint(x: x, y: y),
                size: CGSize(width: width, height: height)
            )
        }
    }
}

extension Element {
    /// Wraps the element in an `Aligned` element with the provided parameters.
    ///
    /// - parameters:
    ///   - vertically: The vertical alignment. Defaults to `.centered`.
    ///   - horizontally: The horizontal alignment. Defaults to `.centered`.
    ///
    public func aligned(
        vertically: Aligned.VerticalAlignment = .center,
        horizontally: Aligned.HorizontalAlignment = .center
    ) -> Aligned {
        Aligned(
            vertically: vertically,
            horizontally: horizontally,
            wrapping: self
        )
    }
}
