/// An element that sizes all of its children equally, stacking them according to
/// the specified `direction` and spacing them according to the specified `gutter`.
public struct EqualSizeStack: Element {

    /// The direction in which this element will stack its children.
    public var direction: Direction

    /// The amount of space between children in this element.
    public var gutter: CGFloat

    /// The child elements to be laid out.
    public var children: [Element]

    /// - Parameters:
    ///     - direction: The direction in which this element will stack its children.
    ///     - gutter: The amount of space between children in this element. Defaults to 0.
    ///     - children: The child elements to be laid out. Defaults to an empty array.
    ///     - configure: A closure allowing the element to be further customized. Defaults to a no-op.
    public init(
        direction: Direction,
        gutter: CGFloat = 0,
        children: [Element] = [],
        configure: (inout EqualSizeStack) -> Void = { _ in })
    {
        self.direction = direction
        self.gutter = gutter
        self.children = children
        configure(&self)
    }

    public var content: ElementContent {
        let layout = EqualSizeLayout(direction: direction, gutter: gutter)
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

extension EqualSizeStack {

    public enum Direction {
        case vertical
        case horizontal
    }

}

extension EqualSizeStack {

    /// A layout that sizes all of its children equally, stacking them according to
    /// the specified `direction` and spacing them according to the specified `gutter`.
    fileprivate struct EqualSizeLayout: Layout {

        /// The direction in which this layout will stack its children.
        var direction: Direction

        /// The amount of space between children in this layout.
        var gutter: CGFloat

        /// - Parameters:
        ///     - direction: The direction in which this layout will stack its children.
        ///     - gutter: The amount of space between children in this layout.
        init(direction: Direction, gutter: CGFloat) {
            self.direction = direction
            self.gutter = gutter
        }

        func measure(in constraint: SizeConstraint, items: [(traits: Void, content: Measurable)]) -> CGSize {
            var totalSize = items
                .map { $1.measure(in: constraint) }
                .reduce(into: CGSize.zero) { totalSize, itemSize in
                    switch direction {
                    case .horizontal:
                        totalSize.width += itemSize.width
                        totalSize.height = max(totalSize.height, itemSize.height)
                    case .vertical:
                        totalSize.width = max(totalSize.width, itemSize.width)
                        totalSize.height += itemSize.height
                    }
            }

            switch direction {
            case .horizontal:
                totalSize.width += gutter * CGFloat(items.count - 1)
            case .vertical:
                totalSize.height += gutter * CGFloat(items.count - 1)
            }

            return totalSize
        }

        func layout(size: CGSize, items: [(traits: (), content: Measurable)]) -> [LayoutAttributes] {
            guard items.count > 0 else { return [] }

            let baseSize: CGSize
            switch direction {
            case .horizontal:
                baseSize = CGSize(
                    width: (size.width - (gutter * CGFloat(items.count - 1))) / CGFloat(items.count),
                    height: size.height)
            case .vertical:
                baseSize = CGSize(
                    width: size.width,
                    height: (size.height - (gutter * CGFloat(items.count - 1))) / CGFloat(items.count))
            }

            return Array(repeating: LayoutAttributes(size: baseSize), count: items.count)
                .enumerated()
                .map { index, attributes in
                    var attributes = attributes
                    switch direction {
                    case .horizontal:
                        attributes.frame.origin.x = (baseSize.width + gutter) * CGFloat(index)
                    case .vertical:
                        attributes.frame.origin.y = (baseSize.height + gutter) * CGFloat(index)
                    }
                    return attributes
            }
        }

    }

}
