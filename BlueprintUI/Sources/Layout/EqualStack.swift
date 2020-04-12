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
        configure: (inout EqualStack) -> Void = { _ in })
    {
        self.direction = direction
        configure(&self)
    }

    public var content: ElementContent {
        let layout = EqualLayout(direction: direction, spacing: spacing)
        return ElementContent(layout: layout) {
            for child in children {
                $0.add(element: child)
            }
        }
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
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

    fileprivate struct EqualLayout: Layout {
        
        var direction: Direction
        var spacing: CGFloat

        public func layout(in constraint : SizeConstraint, items: [LayoutItem<Self>]) -> LayoutResult {
                        
            LayoutResult(
                size: {
                    let itemSizes = items.map { $0.content.size(in: constraint) }

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
                },
                layoutAttributes: { size in
                    guard items.count > 0 else { return [] }

                    let itemSize: CGSize
                    switch direction {
                    case .horizontal:
                        itemSize = CGSize(
                            width: (size.width - (spacing * CGFloat(items.count - 1))) / CGFloat(items.count),
                            height: size.height
                        )
                    case .vertical:
                        itemSize = CGSize(
                            width: size.width,
                            height: (size.height - (spacing * CGFloat(items.count - 1))) / CGFloat(items.count)
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
            )
        }
    }
}
