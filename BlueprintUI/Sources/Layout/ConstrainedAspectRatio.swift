import UIKit

/// Constrains the size of the content element to an aspect ratio.
public struct ConstrainedAspectRatio: Element {
    /// Represents whether the content element's size should be expanded to fill its parent
    /// or shrunk to fit it.
    public enum ContentMode: Equatable {
        /// Expand the content to fill its parent.
        case fill
        /// Shrink the content to fit within its parent.
        case fit

        func constrain(size: CGSize, to aspectRatio: AspectRatio) -> CGSize {
            let constrainedHeight = aspectRatio.height(forWidth: size.width)
            let constrainedWidth = aspectRatio.width(forHeight: size.height)

            switch self {
            case .fill:
                if constrainedWidth > size.width {
                    return CGSize(width: constrainedWidth, height: size.height)
                } else if constrainedHeight > size.height {
                    return CGSize(width: size.width, height: constrainedHeight)
                }

            case .fit:
                if constrainedWidth < size.width {
                    return CGSize(width: constrainedWidth, height: size.height)
                } else if constrainedHeight < size.height {
                    return CGSize(width: size.width, height: constrainedHeight)
                }
            }

            return size
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
    public init(aspectRatio: AspectRatio, contentMode: ContentMode = .fill, wrapping wrappedElement: Element) {
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
        
        func layout(in constraint: SizeConstraint, child: MeasurableChild) -> SingleChildLayoutResult {
            SingleChildLayoutResult(
                size: {
                    let size = child.size(in: constraint)
                    return contentMode.constrain(size: size, to: aspectRatio)
                },
                layoutAttributes: { LayoutAttributes(size: $0) }
            )
        }
    }
}
