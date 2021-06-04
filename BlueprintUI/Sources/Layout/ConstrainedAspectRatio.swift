import UIKit

/// Constrains the size of the content element to an aspect ratio.
public struct ConstrainedAspectRatio: Element {
    /// Represents whether the content element's size should be expanded to fill its parent
    /// or shrunk to fit it.
    public enum ContentMode: Equatable {
        /// The content will be sized to fill its parents largest dimension, while maintaining the
        /// specified aspect ratio.
        ///
        /// If the parent has unconstrained dimensions, the content size will be used for that
        /// dimension. This means that in an unconstrained measurement, this is equivalent to
        /// `fitContent`.
        case fillParent

        /// The content will be sized to fit its parents smallest dimension, while maintaining the
        /// specified aspect ratio.
        ///
        /// If the parent has unconstrained dimensions, the content size will be used for that
        /// dimension. This means that in an unconstrained measurement, this is equivalent to
        /// `shrinkContent`.
        case fitParent

        /// The content will grow in whichever dimension is needed to maintain the aspect ratio,
        /// while ensuring the content still fits.
        ///
        /// This mode does not take the parent into account, so the layout may not end up with the
        /// specified aspect ratio.
        case fitContent

        /// The content will shrink in whichever dimension is needed to maintain the aspect ratio,
        /// meaning it may be smaller in one dimension than the measured size.
        ///
        /// This mode does not take the parent into account, so the layout may not end up with the
        /// specified aspect ratio.
        case shrinkContent

        func constrain(
            contentSize: CGSize,
            in constraint: SizeConstraint,
            to aspectRatio: AspectRatio
        ) -> CGSize {
            return .zero
        }
    }

    /// The element being constrained.
    public var wrappedElement: Element
    /// The target aspect ratio.
    public var aspectRatio: AspectRatio
    /// Whether the aspect ratio should be reached by expanding the content element's size to fill its parent
    /// or shrinking it to fit.
    public var contentMode: ContentMode

    /// Initializes with the given properties.
    ///
    /// - parameters:
    ///   - aspectRatio: The aspect ratio that the content size should match.
    ///   - contentMode: Whether the aspect ratio should be reached by expanding the content
    ///     element's size to fill its parent or shrinking it to fit.
    ///   - wrapping: The content element.
    public init(aspectRatio: AspectRatio, contentMode: ContentMode = .fitParent, wrapping wrappedElement: Element) {
        self.aspectRatio = aspectRatio
        self.contentMode = contentMode
        self.wrappedElement = wrappedElement
    }

    public var content: ElementContent {
        return ElementContent(child: wrappedElement, layout: Layout(aspectRatio: aspectRatio, contentMode: contentMode))
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }

    private struct Layout: SingleChildLayout {
        var aspectRatio: AspectRatio
        var contentMode: ContentMode

        func measure(in sizeConstraint: SizeConstraint, child: Measurable) -> CGSize {
            let contentSize = child.measure(in: sizeConstraint)
            return contentMode.constrain(
                contentSize: contentSize,
                in: sizeConstraint,
                to: aspectRatio
            )
        }

        func layout(size: CGSize, child: Measurable) -> LayoutAttributes {
            return LayoutAttributes(size: size)
        }
    }
}


public extension Element {
    ///
    /// Constrains the element to the provided aspect ratio.
    ///
    /// - parameters:
    ///   - aspectRatio: The aspect ratio that the content size should match.
    ///   - contentMode: Whether the aspect ratio should be reached by expanding the content
    ///     element's size to fill its parent or shrinking it to fit.
    ///
    func constrainedTo(
        aspectRatio: AspectRatio,
        contentMode: ConstrainedAspectRatio.ContentMode = .fitParent
    ) -> ConstrainedAspectRatio
    {
        ConstrainedAspectRatio(aspectRatio: aspectRatio, contentMode: contentMode, wrapping: self)
    }
}
