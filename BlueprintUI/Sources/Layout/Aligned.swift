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

        func layoutMode(in mode: StrictPressureMode) -> StrictPressureMode {
            switch (self, mode) {
            case (.fill, .fill):
                return .fill
            default:
                return .natural
            }
        }
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

        func layoutMode(in mode: StrictPressureMode) -> StrictPressureMode {
            switch (self, mode) {
            case (.fill, .fill):
                return .fill
            default:
                return .natural
            }
        }
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

        func sizeThatFits(proposal: SizeConstraint, subview: LayoutSubview, cache: inout Cache) -> CGSize {
            subview.sizeThatFits(proposal)
        }

        func placeSubview(in bounds: CGRect, proposal: SizeConstraint, subview: LayoutSubview, cache: inout ()) {
            let x: CGFloat
            let y: CGFloat

            let size = subview.sizeThatFits(proposal)
            let clampedSize = size.upperBounded(maxWidth: bounds.width, maxHeight: bounds.height)

            let width: CGFloat
            let height: CGFloat

            switch horizontalAlignment {
            case .leading:
                x = 0
                width = clampedSize.width
            case .center:
                x = 0.5
                width = clampedSize.width
            case .trailing:
                x = 1
                width = clampedSize.width
            case .fill:
                x = 0
                width = bounds.width
            }

            switch verticalAlignment {
            case .top:
                y = 0
                height = clampedSize.height
            case .center:
                y = 0.5
                height = clampedSize.height
            case .bottom:
                y = 1
                height = clampedSize.height
            case .fill:
                y = 0
                height = bounds.height
            }

            let position = CGPoint(x: bounds.minX + x * bounds.width, y: bounds.minY + y * bounds.height)

            subview.place(
                at: position,
                anchor: UnitPoint(x: x, y: y),
                size: CGSize(width: width, height: height)
            )
        }
        
        func layout(in context: StrictLayoutContext, child: StrictLayoutable) -> StrictLayoutAttributes {

            let proposedSize = context.proposedSize

            // each axis will be `fill` if both are true:
            // - context is already `fill`
            // - the alignment is `fill`
            // otherwise, use `natural`
            let options = StrictLayoutOptions(
                mode: AxisVarying(
                    horizontal: horizontalAlignment.layoutMode(in: context.mode.horizontal),
                    vertical: verticalAlignment.layoutMode(in: context.mode.vertical)
                )
            )

            let childSize = child.layout(in: proposedSize, options: options)

            let x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat

            if let proposedHeight = proposedSize.height.constrainedValue, context.mode.vertical == .fill {
               // In `fill` mode, we fill the space and position the child within it.
               height = proposedHeight
               switch verticalAlignment {
               case .top, .fill:
                   y = 0
               case .center:
                   y = (proposedHeight - childSize.height) / 2.0
               case .bottom:
                   y = proposedHeight - childSize.height
               }
           } else {
                // In `natural` mode, Aligned is layout-neutral.
                height = childSize.height
                y = 0
            }

            if let proposedWidth = proposedSize.width.constrainedValue, context.mode.horizontal == .fill {
                width = proposedWidth
                switch horizontalAlignment {
                case .leading, .fill:
                    x = 0
                case .center:
                    x = (proposedWidth - childSize.width) / 2.0
                case .trailing:
                    x = proposedWidth - childSize.width
                }
            } else {
                width = childSize.width
                x = 0
            }

            return StrictLayoutAttributes(
                size: CGSize(width: width, height: height),
                childPositions: [CGPoint(x: x, y: y)]
            )
        }
    }


}

extension CGSize {
    func upperBounded(maxWidth: CGFloat, maxHeight: CGFloat) -> CGSize {
        CGSize(width: min(width, maxWidth), height: min(height, maxHeight))
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
