import UIKit

/// Aligns a content element within itself. The vertical and horizontal alignment may be set independently.
public struct Aligned: Element {
    /// Describes how the content will be vertically aligned.
    public enum VerticalAlignment {
        /// Aligns the content to the top edge.
        case top
        /// Centers the content vertically.
        case center
        /// Aligns the content to the bottom edge.
        case bottom
    }

    /// Describes how the content will be horizontally aligned.
    public enum HorizontalAlignment {
        /// Aligns the content to the leading edge.
        case leading
        /// Centers the content horizontally.
        case center
        /// Aligns the content to the trailing edge.
        case trailing
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
            }

            switch horizontalAlignment {
            case .leading:
                attributes.frame.origin.x = 0
            case .center:
                attributes.frame.origin.x = (size.width - constrainedMeasurement.width) / 2.0
            case .trailing:
                attributes.frame.origin.x = size.width - constrainedMeasurement.width
            }

            return attributes
        }

        func sizeThatFits(
            proposal: SizeConstraint,
            subelement: Subelement,
            environment: Environment
        ) -> CGSize {
            subelement.sizeThatFits(proposal)
        }

        func placeSubelement(
            in size: CGSize,
            subelement: Subelement,
            environment: Environment
        ) {
            let x: CGFloat
            let y: CGFloat

            let subelementSize = subelement
                .sizeThatFits(SizeConstraint(size))
                .upperBounded(by: size)

            switch horizontalAlignment {
            case .leading:
                x = 0
            case .center:
                x = 0.5
            case .trailing:
                x = 1
            }

            switch verticalAlignment {
            case .top:
                y = 0
            case .center:
                y = 0.5
            case .bottom:
                y = 1
            }

            let position = CGPoint(x: x * size.width, y: y * size.height)

            subelement.place(
                at: position,
                anchor: UnitPoint(x: x, y: y),
                size: subelementSize
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

extension Aligned: ComparableElement {
    public func isEquivalent(to other: Aligned) -> Bool {
        guard verticalAlignment == other.verticalAlignment,
              horizontalAlignment == other.horizontalAlignment
        else {
            return false
        }

        guard let selfComparable = wrappedElement as? AnyComparableElement,
              let otherComparable = other.wrappedElement as? AnyComparableElement
        else {
            return false
        }
        return selfComparable.anyIsEquivalent(to: otherComparable)
    }
}
