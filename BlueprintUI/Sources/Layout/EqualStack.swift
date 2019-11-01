/// An element that sizes all of its children equally, stacking them according to
/// the specified `direction` and spacing them according to the specified `spacing`.
///
/// - Note: A stack is measured to accommodate its largest child in each axis.
/// - Note: Children are laid out according to `roundingScale`. Any leftover space
///         will be assigned to the last child.
public struct EqualStack: Element {

    /// The direction in which this element will stack its children.
    public var direction: Direction

    /// The amount of space between children in this element. Defaults to 0.
    public var spacing: CGFloat = 0

    /// The child elements to be laid out. Defaults to an empty array.
    public var children: [Element] = []

    /// The scale to which pixel measurements will be rounded. Defaults to `UIScreen.main.scale`.
    public var roundingScale: CGFloat = UIScreen.main.scale

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
        let layout = EqualLayout(direction: direction, spacing: spacing, roundingScale: roundingScale)
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
        var roundingScale: CGFloat

        func measure(in constraint: SizeConstraint, items: [(traits: Void, content: Measurable)]) -> CGSize {
            let itemSizes = items.map { $1.measure(in: constraint) }

            let maximumItemWidth = itemSizes.map { $0.width }.max() ?? 0
            let maximumItemHeight = itemSizes.map { $0.height }.max() ?? 0

            let totalSize: CGSize
            switch direction {
            case .horizontal:
                totalSize = CGSize(
                    width: maximumItemWidth * CGFloat(items.count) + spacing * CGFloat(items.count - 1),
                    height: maximumItemHeight)
            case .vertical:
                totalSize = CGSize(
                    width: maximumItemWidth,
                    height: maximumItemHeight * CGFloat(items.count) + spacing * CGFloat(items.count - 1))
            }

            return totalSize
        }

        func layout(size: CGSize, items: [(traits: (), content: Measurable)]) -> [LayoutAttributes] {
            guard items.count > 0 else { return [] }

            var result: [LayoutAttributes] = []

            let itemSize: CGSize
            switch direction {
            case .horizontal:
                let itemWidth = (size.width - (spacing * CGFloat(items.count - 1))) / CGFloat(items.count)
                itemSize = CGSize(
                    width: itemWidth.rounded(.toNearestOrAwayFromZero, by: roundingScale),
                    height: size.height)
            case .vertical:
                let itemHeight = (size.height - (spacing * CGFloat(items.count - 1))) / CGFloat(items.count)
                itemSize = CGSize(
                    width: size.width,
                    height: itemHeight.rounded(.toNearestOrAwayFromZero, by: roundingScale))
            }

            var cumulativeSize: CGFloat = 0

            // Assign the fixed itemSize to the first n-1 items
            for index in 0..<items.count - 1 {
                var attributes = LayoutAttributes(size: itemSize)

                switch direction {
                case .horizontal:
                    attributes.frame.origin.x = cumulativeSize
                    cumulativeSize += itemSize.width + spacing
                case .vertical:
                    attributes.frame.origin.y = cumulativeSize
                    cumulativeSize += itemSize.height + spacing
                }

                result.append(attributes)
            }

            // Assign the remaining space to the nth item
            switch direction {
            case .horizontal:
                result.append(
                    LayoutAttributes(frame: CGRect(
                        x: cumulativeSize,
                        y: 0,
                        width: size.width - cumulativeSize,
                        height: itemSize.height)))
            case .vertical:
                result.append(
                    LayoutAttributes(frame: CGRect(
                        x: 0,
                        y: cumulativeSize,
                        width: itemSize.width,
                        height: size.height - cumulativeSize)))
            }

            return result
        }

    }

}
