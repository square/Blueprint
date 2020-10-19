import UIKit

/// Constrains the size of the content element to a fraction of the parent's layout space.
public struct ConstrainedSizeFraction: Element {
    /// The element being constrained.
    public var wrappedElement: Element
    /// The fraction of the parent's horizontal layout space the content element should occupy. `nil` if the width is
    /// unconstrained.
    public var fractionalWidth: CGFloat?
    /// The fraction of the parent's vertical layout space the content element should occupy. `nil` if the height is
    /// unconstrained.
    public var fractionalHeight: CGFloat?

    /// Initializes with the given properties.
    ///
    /// - parameters:
    ///   - fractionalWidth: The fraction of the parent's horizontal layout space the content element should occupy. `nil` if
    ///   the width is unconstrained. By default, `nil`.
    ///   - fractionalHeight: The fraction of the parent's vertical layout space the content element should occupy. `nil` if
    ///   the height is unconstrained. By default, `nil`.
    ///   - wrapping: The content element.
    public init(fractionalWidth: CGFloat? = nil, fractionalHeight: CGFloat? = nil, wrapping wrappedElement: Element) {
        precondition(
            fractionalWidth.map { $0 >= 0 && $0 <= 1} ?? true,
            "The provided width fraction must be a value in the range of `0...1`."
        )
        precondition(
            fractionalHeight.map { $0 >= 0 && $0 <= 1} ?? true,
            "The provided height fraction must be a value in the range of `0...1`."
        )

        self.fractionalWidth = fractionalWidth
        self.fractionalHeight = fractionalHeight
        self.wrappedElement = wrappedElement
    }

    public var content: ElementContent {
        ElementContent(
            child: wrappedElement,
            layout: Layout(width: fractionalWidth, height: fractionalHeight)
        )
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }

    private struct Layout: SingleChildLayout {
        var width: CGFloat?
        var height: CGFloat?

        func measure(in sizeConstraint: SizeConstraint, child: Measurable) -> CGSize {
            /// Get the target layout space, constraining it by the specified fractions.
            let targetWidth = width.map { $0 * sizeConstraint.width.maximum }
            let targetHeight = height.map { $0 * sizeConstraint.height.maximum }

            let constraint = SizeConstraint(
                width: targetWidth.map { .atMost($0) } ?? .unconstrained,
                height: targetHeight.map { .atMost($0) } ?? .unconstrained
            )

            /// Measure the child in the constrained layout space.
            let measurement = child.measure(in: constraint)

            /// Override the child's measurement with a target dimension if one exists.
            return CGSize(
                width: targetWidth ?? measurement.width,
                height: targetHeight ?? measurement.height
            )
        }

        func layout(size: CGSize, child: Measurable) -> LayoutAttributes {
            return LayoutAttributes(size: size)
        }
    }
}


public extension Element {
    /// Constrains the element to a fraction of its parent's size.
    ///
    /// - parameters:
    ///   - fractionalWidth: The fraction of the parent's horizontal layout space the element should occupy. `nil`
    ///   if the width is unconstrained. By default, `nil`.
    ///   - fractionalHeight: The fraction of the parent's vertical layout space the element should occupy. `nil`
    ///   if the height is unconstrained. By default, `nil`.
    func constrainedTo(
        fractionalWidth: CGFloat? = nil,
        fractionalHeight: CGFloat? = nil
    ) -> ConstrainedSizeFraction
    {
        ConstrainedSizeFraction(fractionalWidth: fractionalWidth, fractionalHeight: fractionalHeight, wrapping: self)
    }
}
