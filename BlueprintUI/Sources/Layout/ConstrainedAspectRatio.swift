/// Constrains the size of the content element to an aspect ratio.
public struct ConstrainedAspectRatio: Element {
    /// Represents whether the content element's size should be expanded or shrunk to match the
    /// constraint aspect ratio.
    public enum Constraint {
        case expand
        case shrink

        func constrain(size: CGSize, to aspectRatio: AspectRatio) -> CGSize {
            let constrainedHeight = aspectRatio.height(forWidth: size.width)
            let constrainedWidth = aspectRatio.width(forHeight: size.height)

            switch self {
            case .expand:
                if constrainedWidth > size.width {
                    return CGSize(width: constrainedWidth, height: size.height)
                } else if constrainedHeight > size.height {
                    return CGSize(width: size.width, height: constrainedHeight)
                }

            case .shrink:
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
    /// Whether the aspect ratio should be reached by expanding the content element's size or shrinking it.
    public var constraint: Constraint

    /// Initializes with the given properties.
    ///
    /// - parameters:
    ///   - aspectRatio: The aspect ratio that the content size should match.
    ///   - constraint: Whether the aspect ratio should be reached by expanding the content
    ///     element's size or shrinking it.
    ///   - wrapping: The content element.
    public init(aspectRatio: AspectRatio, constraint: Constraint = .expand, wrapping wrappedElement: Element) {
        self.aspectRatio = aspectRatio
        self.constraint = constraint
        self.wrappedElement = wrappedElement
    }

    public var content: ElementContent {
        return ElementContent(child: wrappedElement, layout: Layout(aspectRatio: aspectRatio, constraint: constraint))
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }

    private struct Layout: SingleChildLayout {
        var aspectRatio: AspectRatio
        var constraint: Constraint

        func measure(in sizeConstraint: SizeConstraint, child: Measurable) -> CGSize {
            let size = child.measure(in: sizeConstraint)
            return constraint.constrain(size: size, to: aspectRatio)
        }

        func layout(size: CGSize, child: Measurable) -> LayoutAttributes {
            return LayoutAttributes(size: size)
        }
    }
}
