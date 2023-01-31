import UIKit

/// An element that sizes its children equally, stacking them in the primary axis according to
/// the specified `direction` and spacing them according to the specified `spacing`. In the
/// secondary axis, children are justified to fill the space of the largest child.
///
/// - Note: A stack measures itself by determining its largest child in each axis, and
///         in the case of the primary axis, multiplying by `children.count` (accounting
///         for `spacing` as necessary).
public struct EqualStack: Element {

    /// The direction in which this element will stack its children.
    public var direction: Direction

    /// The amount of space between children in this element. Defaults to 0.
    public var spacing: CGFloat = 0

    /// The child elements to be laid out. Defaults to an empty array.
    public var children: [Element] = []

    /// - Parameters:
    ///     - direction: The direction in which this element will stack its children.
    ///     - configure: A closure allowing the element to be further customized. Defaults to a no-op.
    public init(
        direction: Direction,
        configure: (inout EqualStack) -> Void = { _ in }
    ) {
        self.direction = direction
        configure(&self)
    }

    /// Initializer using result builder to declaritively build up a stack.
    /// - Parameters:
    ///   - direction: Direction of the stack.
    ///   - children: A block containing all elements to be included in the stack.
    public init(
        direction: Direction,
        spacing: CGFloat = 0,
        @ElementBuilder<Child> elements: () -> [Child]
    ) {
        self.init(direction: direction)
        self.spacing = spacing
        children = elements().map(\.element)
    }

    public var content: ElementContent {
        let layout = EqualLayout(direction: direction, spacing: spacing)
        return ElementContent(layout: layout) {
            for child in children {
                $0.add(element: child)
            }
        }
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }

    public mutating func add(child: Element) {
        children.append(child)
    }

}

extension EqualStack {

    public enum Direction {
        case vertical
        case horizontal
    }

}

extension EqualStack {

    fileprivate struct EqualLayout: Layout, StrictLayout {

        var direction: Direction
        var spacing: CGFloat

        func measure(in constraint: SizeConstraint, items: [(traits: Void, content: Measurable)]) -> CGSize {
            guard items.count > 0 else { return .zero }

            let totalSpacing = (spacing * CGFloat(items.count - 1))
            let itemConstraint: SizeConstraint
            switch direction {
            case .horizontal:
                itemConstraint = SizeConstraint(
                    width: (constraint.width - totalSpacing) / CGFloat(items.count),
                    height: constraint.height
                )
            case .vertical:
                itemConstraint = SizeConstraint(
                    width: constraint.width,
                    height: (constraint.height - totalSpacing) / CGFloat(items.count)
                )
            }
            let itemSizes = items.map { $1.measure(in: itemConstraint) }

            let maximumItemWidth = itemSizes.map { $0.width }.max() ?? 0
            let maximumItemHeight = itemSizes.map { $0.height }.max() ?? 0

            let totalSize: CGSize
            switch direction {
            case .horizontal:
                totalSize = CGSize(
                    width: maximumItemWidth * CGFloat(items.count) + spacing * CGFloat(items.count - 1),
                    height: maximumItemHeight
                )
            case .vertical:
                totalSize = CGSize(
                    width: maximumItemWidth,
                    height: maximumItemHeight * CGFloat(items.count) + spacing * CGFloat(items.count - 1)
                )
            }

            return totalSize
        }

        func layout(size: CGSize, items: [(traits: (), content: Measurable)]) -> [LayoutAttributes] {
            guard items.count > 0 else { return [] }

            let totalSpacing = (spacing * CGFloat(items.count - 1))
            let itemSize: CGSize
            switch direction {
            case .horizontal:
                itemSize = CGSize(
                    width: (size.width - totalSpacing) / CGFloat(items.count),
                    height: size.height
                )
            case .vertical:
                itemSize = CGSize(
                    width: size.width,
                    height: (size.height - totalSpacing) / CGFloat(items.count)
                )
            }

            var result: [LayoutAttributes] = []

            for index in 0..<items.count {
                var attributes = LayoutAttributes(size: itemSize)

                switch direction {
                case .horizontal:
                    attributes.frame.origin.x = (itemSize.width + spacing) * CGFloat(index)
                case .vertical:
                    attributes.frame.origin.y = (itemSize.height + spacing) * CGFloat(index)
                }

                result.append(attributes)
            }

            return result
        }

        func sizeThatFits(proposal: SizeConstraint, subviews: Subviews, cache: inout Cache) -> CGSize {
            guard subviews.count > 0 else { return .zero }

            let totalSpacing = (spacing * CGFloat(subviews.count - 1))
            let itemProposal: SizeConstraint
            switch direction {
            case .horizontal:
                itemProposal = .init(
                    width: proposal.width.map { ($0 - totalSpacing) / CGFloat(subviews.count) },
                    height: proposal.height
                )
            case .vertical:
                itemProposal = .init(
                    width: proposal.width,
                    height: proposal.height.map { ($0 - totalSpacing) / CGFloat(subviews.count) }
                )
            }
            let itemSizes = subviews.map { $0.sizeThatFits(itemProposal) }

            let maximumItemWidth = itemSizes.map { $0.width }.max() ?? 0
            let maximumItemHeight = itemSizes.map { $0.height }.max() ?? 0

            let totalSize: CGSize
            switch direction {
            case .horizontal:
                totalSize = CGSize(
                    width: maximumItemWidth * CGFloat(subviews.count) + spacing * CGFloat(subviews.count - 1),
                    height: maximumItemHeight
                )
            case .vertical:
                totalSize = CGSize(
                    width: maximumItemWidth,
                    height: maximumItemHeight * CGFloat(subviews.count) + spacing * CGFloat(subviews.count - 1)
                )
            }

            return totalSize
        }

        func placeSubviews(in bounds: CGRect, proposal: SizeConstraint, subviews: Subviews, cache: inout ()) {
            guard subviews.count > 0 else { return }
            let size = bounds.size

            let totalSpacing = (spacing * CGFloat(subviews.count - 1))
            let itemSize: CGSize
            switch direction {
            case .horizontal:
                itemSize = CGSize(
                    width: (size.width - totalSpacing) / CGFloat(subviews.count),
                    height: size.height
                )
            case .vertical:
                itemSize = CGSize(
                    width: size.width,
                    height: (size.height - totalSpacing) / CGFloat(subviews.count)
                )
            }

            for (subview, index) in zip(subviews, 0...) {
                var origin = bounds.origin
                switch direction {
                case .horizontal:
                    origin.x += (itemSize.width + spacing) * CGFloat(index)
                case .vertical:
                    origin.y += (itemSize.height + spacing) * CGFloat(index)
                }

                subview.place(at: origin, size: itemSize)
            }
        }

        func layout(in context: StrictLayoutContext, children: [StrictLayoutChild]) -> StrictLayoutAttributes {
            guard !children.isEmpty else { return .init(size: .zero) }

            let totalSpacing = (spacing * CGFloat(children.count - 1))

            let itemProposal: SizeConstraint

            switch direction {
            case .horizontal:
                let width: SizeConstraint.Axis
                if let proposedWidth = context.proposedSize.width.constrainedValue {
                    width = .atMost((proposedWidth - totalSpacing) / CGFloat(children.count))
                } else {
                    width = .unconstrained
                }

                itemProposal = SizeConstraint(
                    width: width,
                    height: context.proposedSize.height
                )

            case .vertical:
                let height: SizeConstraint.Axis
                if let proposedHeight = context.proposedSize.height.constrainedValue {
                    height = .atMost((proposedHeight - totalSpacing) / CGFloat(children.count))
                } else {
                    height = .unconstrained
                }

                itemProposal = SizeConstraint(
                    width: context.proposedSize.width,
                    height: height
                )
            }

            let options: StrictLayoutOptions
            switch direction {
            case .horizontal:
                options = StrictLayoutOptions(
                    mode: .init(
                        horizontal: nil,
                        vertical: context.mode.vertical == .fill ? .fill : nil
                    )
                )
            case .vertical:
                options = StrictLayoutOptions(
                    mode: .init(
                        horizontal: context.mode.horizontal == .fill ? .fill : nil,
                        vertical: nil
                    )
                )
            }

            let childSizes = children.map { (traits: Void, layoutable: StrictLayoutable) in
                layoutable.layout(
                    in: itemProposal,
                    options: options
                )
            }

            let childWidth = (context.mode.horizontal == .fill ? itemProposal.width.constrainedValue : nil)
                ?? childSizes.map(\.width).max()
                ?? 0
            let childHeight = (context.mode.vertical == .fill ? itemProposal.height.constrainedValue : nil)
                ?? childSizes.map(\.height).max()
                ?? 0

            let itemSize = CGSize(
                width: childWidth,
                height: childHeight
            )

            for child in children {
                _ = child.layoutable.layout(
                    in: SizeConstraint(itemSize),
                    options: StrictLayoutOptions(
                        maxAllowedLayoutCount: 2,
                        mode: .init(horizontal: .fill, vertical: .fill)
                    )
                )
            }

            let totalSize: CGSize
            switch direction {
            case .horizontal:
                totalSize = CGSize(
                    width: itemSize.width * CGFloat(children.count) + totalSpacing,
                    height: itemSize.height
                )
            case .vertical:
                totalSize = CGSize(
                    width: itemSize.width,
                    height: itemSize.height * CGFloat(children.count) + totalSpacing
                )
            }

            let childPositions = (0..<children.count).map { index in
                switch direction {
                case .horizontal:
                    return CGPoint(
                        x: (itemSize.width + spacing) * CGFloat(index),
                        y: 0
                    )
                case .vertical:
                    return CGPoint(
                        x: 0,
                        y: (itemSize.height + spacing) * CGFloat(index)
                    )
                }
            }

            return StrictLayoutAttributes(
                size: totalSize,
                childPositions: childPositions
            )
        }
    }

}

/// Wraps around an Element for consistency with `StackLayout.Child` and `GridRowChild`.
/// In the future this struct could hold traits used for laying out inside an EqualStack
extension EqualStack {
    public struct Child: ElementBuilderChild {
        public let element: Element

        public init(_ element: Element) {
            self.element = element
        }
    }
}
