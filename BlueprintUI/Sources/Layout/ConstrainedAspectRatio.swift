import UIKit

/// Constrains the size of the content element to an aspect ratio.
public struct ConstrainedAspectRatio: Element {
    /// Represents how the content should size itself relative to its parent.
    public enum ContentMode: Equatable {
        /// The content will be sized to fill its parent while
        /// maintaining the specified aspect ratio.
        ///
        /// In ``LayoutMode/legacy`` layout mode, if the parent is unconstrained in all dimensions,
        /// the content size will be used for measurement and will behave like `fitContent`. If the
        /// parent is unconstrained in one dimension, the element will fill the constrained
        /// dimension.
        ///
        /// In ``LayoutMode/caffeinated``, if the parent is unconstrained in any dimension, this
        /// element will report a size of `infinity`.
        ///
        @available(*, deprecated, message: "Limited utility in Caffeinated Layout")
        case fillParent

        /// The content will be sized to fit within its parent while maintaining the specified
        /// aspect ratio.
        ///
        /// If the parent is unconstrained in one dimension, the element will fit the constrained
        /// dimension.
        ///
        /// In ``LayoutMode/legacy`` layout mode, if the parent is unconstrained in all dimensions,
        /// the content size will be used for measurement and will behave like `fitContent`.
        ///
        /// In ``LayoutMode/caffeinated`` layout mode, if the parent is unconstrained in both
        /// dimensions, this element will report a size of `infinity`.
        ///
        case fitParent

        /// The content will grow in whichever dimension is needed to maintain the aspect ratio,
        /// while ensuring the content still fits.
        ///
        /// This mode does not take the parents applied size constraint into account, so the parent
        /// may ultimately layout the element without the constrained aspect ratio.
        case fitContent

        /// The content will shrink in whichever dimension is needed to maintain the aspect ratio,
        /// meaning it may be smaller in one dimension than the measured size.
        ///
        /// This mode does not take the parents applied size constraint into account, so the parent
        /// may ultimately layout the element without the constrained aspect ratio.
        case shrinkContent

        func constrain(
            contentSize: CGSize,
            in constraint: SizeConstraint,
            to aspectRatio: AspectRatio
        ) -> CGSize {
            let availableHeight: CGFloat
            let availableWidth: CGFloat

            switch self {
            case .fillParent,
                 .fitParent:
                availableHeight = constraint.height.constrainedValue ?? contentSize.height
                availableWidth = constraint.width.constrainedValue ?? contentSize.width
            case .fitContent,
                 .shrinkContent:
                availableHeight = contentSize.height
                availableWidth = contentSize.width
            }

            let constrainedHeight = aspectRatio.height(forWidth: availableWidth)
            let constrainedWidth = aspectRatio.width(forHeight: availableHeight)

            switch self {
            case .fillParent:
                if constraint.width.constrainedValue == nil &&
                    constraint.height.constrainedValue == nil
                {
                    if constrainedWidth > availableWidth {
                        return aspectRatio.size(forWidth: constrainedWidth)
                    } else if constrainedHeight > availableHeight {
                        return aspectRatio.size(forHeight: constrainedHeight)
                    }
                    return contentSize
                } else if constraint.width.constrainedValue == nil {
                    return aspectRatio.size(forWidth: constrainedWidth)
                } else if constraint.height.constrainedValue == nil {
                    return aspectRatio.size(forHeight: constrainedHeight)
                } else if constrainedWidth < availableWidth {
                    return aspectRatio.size(forHeight: constrainedHeight)
                } else {
                    return aspectRatio.size(forWidth: constrainedWidth)
                }

            case .fitParent:
                if constraint.width.constrainedValue == nil &&
                    constraint.height.constrainedValue == nil
                {
                    if constrainedWidth > availableWidth {
                        return aspectRatio.size(forWidth: constrainedWidth)
                    } else if constrainedHeight > availableHeight {
                        return aspectRatio.size(forHeight: constrainedHeight)
                    }
                    return contentSize
                } else if constraint.width.constrainedValue == nil {
                    return aspectRatio.size(forWidth: constrainedWidth)
                } else if constraint.height.constrainedValue == nil {
                    return aspectRatio.size(forHeight: constrainedHeight)
                } else if constrainedWidth > availableWidth {
                    return aspectRatio.size(forHeight: constrainedHeight)
                } else {
                    return aspectRatio.size(forWidth: constrainedWidth)
                }

            case .fitContent:
                if constrainedWidth > availableWidth {
                    return aspectRatio.size(forWidth: constrainedWidth)
                } else if constrainedHeight > availableHeight {
                    return aspectRatio.size(forHeight: constrainedHeight)
                }
                return contentSize

            case .shrinkContent:
                if constrainedWidth < availableWidth {
                    return aspectRatio.size(forWidth: constrainedWidth)
                } else if constrainedHeight < availableHeight {
                    return aspectRatio.size(forHeight: constrainedHeight)
                }
                return contentSize
            }
        }

        func constrain(
            subelement: LayoutSubelement,
            to aspectRatio: AspectRatio,
            in proposal: SizeConstraint
        ) -> CGSize {

            switch self {
            case .fillParent:
                switch (proposal.width, proposal.height) {

                case (.atMost(let maxWidth), .atMost(let maxHeight)):
                    let constrainedWidth = aspectRatio.width(forHeight: maxHeight)

                    if constrainedWidth > maxWidth {
                        // grow width to match height
                        return aspectRatio.size(forHeight: maxHeight)
                    } else {
                        // grow height to match width
                        return aspectRatio.size(forWidth: maxWidth)
                    }

                default:
                    return .infinity
                }

            case .fitParent:
                switch (proposal.width, proposal.height) {
                case (.unconstrained, .unconstrained):
                    return .infinity

                case (.atMost(let maxWidth), .unconstrained):
                    return aspectRatio.size(forWidth: maxWidth)

                case (.unconstrained, .atMost(let maxHeight)):
                    return aspectRatio.size(forHeight: maxHeight)

                case (.atMost(let maxWidth), .atMost(let maxHeight)):
                    let constrainedWidth = aspectRatio.width(forHeight: maxHeight)

                    if constrainedWidth > maxWidth {
                        // too wide, match width and shrink height
                        return aspectRatio.size(forWidth: maxWidth)
                    } else {
                        // match height and shrink width
                        return aspectRatio.size(forHeight: maxHeight)
                    }
                }

            case .fitContent:
                let contentSize = subelement.sizeThatFits(proposal)
                let constrainedWidth = aspectRatio.width(forHeight: contentSize.height)

                if constrainedWidth > contentSize.width {
                    // grow width to match height
                    return aspectRatio.size(forHeight: contentSize.height)
                } else {
                    // grow height to match width
                    return aspectRatio.size(forWidth: contentSize.width)
                }

            case .shrinkContent:
                let contentSize = subelement.sizeThatFits(proposal)
                let constrainedWidth = aspectRatio.width(forHeight: contentSize.height)

                if constrainedWidth < contentSize.width {
                    // shrink width to match height
                    return aspectRatio.size(forHeight: contentSize.height)
                } else {
                    // shrink height to match width
                    return aspectRatio.size(forWidth: contentSize.width)
                }
            }

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
    ///   - contentMode: How the content should size itself relative to its parent.
    ///   - wrapping: The content element.
    public init(aspectRatio: AspectRatio, contentMode: ContentMode = .fitContent, wrapping wrappedElement: Element) {
        self.aspectRatio = aspectRatio
        self.contentMode = contentMode
        self.wrappedElement = wrappedElement
    }

    public var content: ElementContent {
        ElementContent(child: wrappedElement, layout: Layout(aspectRatio: aspectRatio, contentMode: contentMode))
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
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
            LayoutAttributes(size: size)
        }

        func sizeThatFits(
            proposal: SizeConstraint,
            subelement: Subelement,
            environment: Environment,
            cache: inout Cache
        ) -> CGSize {
            contentMode.constrain(subelement: subelement, to: aspectRatio, in: proposal)
        }

        func placeSubelement(
            in size: CGSize,
            subelement: Subelement,
            environment: Environment,
            cache: inout ()
        ) {
            subelement.place(filling: size)
        }
    }
}


extension Element {
    ///
    /// Constrains the element to the provided aspect ratio.
    ///
    /// - parameters:
    ///   - aspectRatio: The aspect ratio that the content size should match.
    ///   - contentMode: How the content should size itself relative to its parent.
    ///
    public func constrainedTo(
        aspectRatio: AspectRatio,
        contentMode: ConstrainedAspectRatio.ContentMode = .fitContent
    ) -> ConstrainedAspectRatio {
        ConstrainedAspectRatio(aspectRatio: aspectRatio, contentMode: contentMode, wrapping: self)
    }
}
