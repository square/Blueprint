import UIKit

/// Like `Row`, `GridRow` displays a list of items in a linear horizontal layout. Unlike `Row`, `GridRow` provides
/// convenience for describing columnar layout.
///
/// Horizontally, `GridRow` children are stretched to fill the available space. Vertically, children are aligned
/// according to the `verticalAlignment` property.
///
/// Children may be sized proportionally or absolutely. Proportionally-sized children are granted a proportion of
/// the total layout space **after** absolutely-sized children and margins have been subtracted.
///
/// ## Example:
///
/// ```
/// GridRow { row in
///   row.verticalAlignment = .fill
///   row.spacing = 8.0
///   row.add(width: .proportional(0.75), child: name)
///   row.add(width: .proportional(0.25), child: number)
///   row.add(width: .absolute(100), child: status)
/// }
/// ```
///
/// ## Expected layout:
///
/// ```
/// ┌────────────────────────────┬─┬────────┬─┬──────────────────┐
/// │            name            │ │ number │ │      status      │
/// │            (75%)           │8│  (25%) │8│     (100 pts)    │
/// │                            │ │        │ │                  │
/// ●──────────── 150 ───────────● ●── 50 ──● ●─────── 100 ──────●
/// └────────────────────────────┴─┴────────┴─┴──────────────────┘
/// ●──────────────────────────── 316 ───────────────────────────●
/// ```
public struct GridRow: Element {
    // MARK: - properties -
    /// How children are aligned vertically. By default, `.fill`.
    public var verticalAlignment: Row.RowAlignment = .fill

    /// The space between children. By default, 0.
    public var spacing: CGFloat = 0

    /// The child elements to be laid out. By default, an empty array.
    public var children: [Child] = []

    // MARK: - initialization -
    public init(configure: (inout GridRow) -> Void = { _ in }) {
        configure(&self)
    }

    /// Initializer using result builder to declaritively build up a grid row.
    /// - Parameter verticalAlignment: How children are aligned vertically. By default, `.fill`.
    /// - Parameter spacing: The space between children. By default, 0.
    /// - Parameter elements: A block containing all elements to be included in the row.
    public init(
        verticalAlignment: Row.RowAlignment = .fill,
        spacing: CGFloat = 0,
        @ElementBuilder<Child> _ elements: () -> [Child]
    ) {
        children = elements()
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
    }

    // MARK: - mutations -
    public mutating func add(width: Width, key: AnyHashable? = nil, child: Element) {
        children.append(Child(width: width, key: key, element: child))
    }

    // MARK: - GridRow+Element -
    public var content: ElementContent {
        ElementContent(layout: GridRowLayout(verticalAlignment: verticalAlignment, spacing: spacing)) { builder in
            children.forEach {
                builder.add(traits: $0.width, key: $0.key, element: $0.element)
            }
        }
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
}

// MARK: - layout -
extension GridRow {
    struct GridRowLayout: Layout {
        let verticalAlignment: Row.RowAlignment
        let spacing: CGFloat

        typealias IndexedProportionalItem = (index: Int, proportion: CGFloat, content: Measurable)
        typealias IndexedSize = (index: Int, size: CGSize)

        static var defaultTraits: GridRow.Width {
            .absolute(0)
        }

        func measure(in constraint: SizeConstraint, items: [(traits: Width, content: Measurable)]) -> CGSize {
            guard items.count > 0 else {
                return .zero
            }

            let frames = _frames(in: constraint, items: items)

            // Measure the row to be as wide as the sum of its children and as tall as its tallest child.
            let size = frames.reduce(.zero) { size, frame in
                CGSize(width: frame.maxX, height: max(size.height, frame.height))
            }

            return size
        }

        func layout(size: CGSize, items: [(traits: Width, content: Measurable)]) -> [LayoutAttributes] {
            guard items.count > 0 else {
                return []
            }

            let frames = _frames(in: SizeConstraint(size), isExactConstraint: true, items: items)
            let attributes = frames.map(LayoutAttributes.init)

            return attributes
        }

        private func items(subelements: Subelements) -> [(traits: Traits, content: Measurable)] {
            subelements.map { subelement in
                let traits = subelement.gridRowLayoutTraits
                let measurable = Measurer { constraint in
                    subelement.sizeThatFits(constraint)
                }
                return (traits, measurable)
            }
        }

        func sizeThatFits(
            proposal: SizeConstraint,
            subelements: Subelements,
            environment: Environment,
            cache: inout Cache
        ) -> CGSize {
            guard subelements.count > 0 else {
                return .zero
            }

            let items = items(subelements: subelements)

            let frames = _frames(in: proposal, items: items)

            // Measure the row to be as wide as the sum of its children and as tall as its tallest child.
            let size = frames.reduce(.zero) { size, frame in
                CGSize(width: frame.maxX, height: max(size.height, frame.height))
            }

            return size
        }

        func placeSubelements(
            in size: CGSize,
            subelements: Subelements,
            environment: Environment,
            cache: inout ()
        ) {
            guard subelements.count > 0 else {
                return
            }

            let items = items(subelements: subelements)
            let frames = _frames(
                in: SizeConstraint(size),
                isExactConstraint: true,
                items: items
            )

            for (frame, subelement) in zip(frames, subelements) {
                subelement.place(at: frame.origin, size: frame.size)
            }
        }

        private typealias GridRowLayoutItem = (traits: Width, content: Measurable)

        /// Compute child frames in a given layout space.
        ///
        /// First, we measure the size of absolutely-sized children. Next, we measure the size of
        /// proportionally-sized children.
        ///
        /// When layout width is constrained, proportionally-sized children receive a portion of the available space.
        /// When it is not, proportionally-sized children are sized relative to each other.
        ///
        /// Finally, we compute the frames of children within the row from left to right, assigning a y-origin
        /// and height which fulfill the row's vertical alignment.
        ///
        /// During layout, the constraint is considered an exact description of the row size (`isExactConstraint`).
        /// This shadows `Stack.VectorConstraint.exactly` conceptually without introducing the greater complexity of
        /// this type, which would go mostly unused here.
        private func _frames(
            in constraint: SizeConstraint,
            isExactConstraint: Bool = false,
            items: [(traits: Width, content: Measurable)]
        ) -> [CGRect] {
            var sizes: [CGSize] = Array(repeating: .zero, count: items.count)

            // Group children by their sizing. Maintain child order by also storing index.
            var absolutelySized: [(index: Int, width: CGFloat, content: Measurable)] = []
            var proportionallySized: [(index: Int, proportion: CGFloat, content: Measurable)] = []
            items.enumerated().forEach { index, item in
                switch item.traits {
                case .absolute(let width):
                    absolutelySized.append((index, width, item.content))
                case .proportional(let proportion):
                    proportionallySized.append((index, proportion, item.content))
                }
            }

            // Measure absolutely-sized children.
            absolutelySized.forEach { index, width, content in
                let fixedWidthConstraint = SizeConstraint(width: .atMost(width), height: constraint.height)
                sizes[index] = CGSize(width: width, height: content.measure(in: fixedWidthConstraint).height)
            }

            // Measure proportionally-sized children.
            switch constraint.width {
            case .atMost(let width):
                let absoluteItemWidth = sizes.map { $0.width }.reduce(0, +)
                let availableWidth = width - absoluteItemWidth - spacing * CGFloat(items.count - 1)
                constrainedProportionalItemSizes(
                    in: constraint,
                    availableWidth: availableWidth,
                    items: proportionallySized
                )
                .forEach { index, size in
                    sizes[index] = size
                }
            case .unconstrained:
                unconstrainedProportionalItemSizes(
                    in: constraint,
                    items: proportionallySized
                )
                .forEach { index, size in
                    sizes[index] = size
                }
            }

            // Begin computing frames by reading the vertical alignment. Vertical alignment determines the y-origin
            // and, in the `.fill` case, the height of the children.
            //
            // The tallest child will be used to size the row unless it is a layout pass, in which the row's height
            // is already known.
            let rowHeight = isExactConstraint
                ? constraint.height.maximum
                : sizes.map { $0.height }.max() ?? 0

            // Define alignment positioning.
            let yVector = _yVector(rowHeight: rowHeight)

            // Compute frames.
            var offset: CGFloat = 0
            return sizes.map { size in
                defer { offset += size.width + spacing }
                let (yOrigin, height) = yVector(size.height)
                return CGRect(x: offset, y: yOrigin, width: size.width, height: height)
            }
        }

        /// When the layout width is constrained, allot the children a portion of the available space.
        ///
        /// Determine the scale of a portion (points per portion), then use it to apply a width to each child.
        func constrainedProportionalItemSizes(
            in constraint: SizeConstraint,
            availableWidth: CGFloat,
            items: [IndexedProportionalItem]
        ) -> [IndexedSize] {
            guard items.count > 0 else {
                return []
            }

            guard availableWidth > 0 else {
                // There's no room to layout so there's no need to perform any measurement.
                return items.map { index, _, _ in (index, .zero) }
            }

            let portionSum = items.map { $0.proportion }.reduce(0, +)
            precondition(
                portionSum > 0,
                "Proportions of a GridRow must sum to a positive number. Found sum: \(portionSum)."
            )
            let scale = availableWidth / portionSum

            return items.map { index, proportion, content in
                let width = scale * proportion
                let fixedWidthConstraint = SizeConstraint(width: .atMost(width), height: constraint.height)
                let size = CGSize(width: width, height: content.measure(in: fixedWidthConstraint).height)
                return (index, size)
            }
        }

        /// When the layout width is unconstrained, size children relative to each other.
        ///
        /// Measure each child's width to find the maximum scale (points per portion). The maximum scale
        /// can be applied to each child to provide widths which satisfy the proportional requirements
        /// between children and provide enough space to layout each child.
        ///
        /// ## Example:
        ///      - proportions:      1,     2,     3
        ///      - measured widths:  10,    25,    24
        ///      - scales:           10,    12.5,  8
        ///      - max scale:        12.5
        ///      - widths:           12.5,  25,    37.5
        private func unconstrainedProportionalItemSizes(
            in constraint: SizeConstraint,
            items: [IndexedProportionalItem]
        ) -> [IndexedSize] {
            var scale: CGFloat = 0
            var measuredSizes: [CGSize] = []

            items.forEach { _, proportion, content in
                let size = content.measure(in: constraint)
                measuredSizes.append(size)
                scale = max(scale, size.width / proportion)
            }

            return zip(items, measuredSizes).map { item, measuredSize in
                let width = scale * item.proportion
                // As this width is at least as wide as the one measured above,
                // the height requirement should not change.
                return (item.index, CGSize(width: width, height: measuredSize.height))
            }
        }

        private func _yVector(rowHeight: CGFloat) -> (CGFloat) -> (origin: CGFloat, height: CGFloat) {
            switch verticalAlignment {
            case .fill:
                return { _ in (0, rowHeight) }
            case .align(let id) where id == .top:
                return { height in (0, height) }
            case .align(let id) where id == .center:
                return { height in ((rowHeight - height) / 2.0, height) }
            case .align(let id) where id == .bottom:
                return { height in (rowHeight - height, height) }
            case .align:
                fatalError("GridRow supports fill, top, center, and bottom alignment.")
            }
        }
    }
}

extension LayoutSubelement {
    var gridRowLayoutTraits: GridRow.GridRowLayout.Traits {
        traits(forLayoutType: GridRow.GridRowLayout.self)
    }
}


// MARK: - child modeling -
extension GridRow {
    /// A child of a `GridRow`.
    public struct Child {
        // MARK: - properties -
        /// The element displayed in the `Grid`.
        public var element: Element
        /// A unique identifier for the child.
        public var key: AnyHashable?
        // The sizing for the element.
        public var width: Width

        // MARK: - initialialization -
        public init(width: Width, key: AnyHashable? = nil, element: Element) {
            self.element = element
            self.key = key
            self.width = width
        }
    }

    /// The sizing and content of a `GridRow` child.
    public enum Width: Equatable {
        /// Assign the child a fixed width equal to the payload.
        case absolute(CGFloat)
        /// Assign the child a proportional width of the available layout width. Note that proportional children
        /// take proportional shares of the available layout width.
        ///
        /// ## Example:
        ///     Available layout width: 100
        ///     Child A: .proportional(1)  -> 25 (100 * 1/4)
        ///     Child B: .proportional(3) -> 75 (100 * 3/4)
        ///
        /// ## Example:
        ///     Available layout width: 100
        ///     Child A: .proportional(0.25)  -> 25 (100 * 1/4)
        ///     Child B: .proportional(0.75) -> 75 (100 * 3/4)
        case proportional(CGFloat)
    }
}

extension Element {
    /// Wraps an element with a `GridRowChild` in order to provide meta information that a `GridRow` can aply to its layout.
    /// - Parameters:
    ///   - key: A unique identifier for the child.
    ///   - width: The sizing for the element.
    /// - Returns: `GridRowChild`
    public func gridRowChild(key: AnyHashable? = nil, width: GridRow.Width) -> GridRow.Child {
        .init(width: width, key: key, element: self)
    }
}

extension GridRow.Child: ElementBuilderChild {
    public init(_ element: Element) {
        self.init(width: .proportional(1), element: element)
    }
}
