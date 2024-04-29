import UIKit


/// Element which lays out children horizontally, wrapping to another row when there is not enough space.
///
/// You may control the layout of each row within the flow layout, by providing a `LineAlignment`,
/// which controls the horizontal alignment of content within a row when it is smaller than its container,
/// and via `ItemAlignment`, which controls the vertical alignment of shorter elements within a row.
///
/// ```swift
/// Flow(itemSpacing: 10, lineSpacing: 10) {
///     OnboardingPill("Food / drink")
///     OnboardingPill("Retail goods").flowChild(key: "aKey")
///     OnboardingPill("Grocery / gourmet / alcohol")
///     OnboardingPill("Beauty / wellness bookings")
///     OnboardingPill("Healthcare services")
///     OnboardingPill("Something else")
/// }
/// ```
///
/// Below is a diagram showing a simple example of a `Flow` layout.
///
/// ```
/// ┌─────────────────────────────────────┐
/// │ ┌─────────┐┌─────────┐┌────────────┐│
/// │ │    1    ││    2    ││     3      ││
/// │ └─────────┘└─────────┘└────────────┘│
/// │ ┌───────┐┌─────┐┌───────────┐       │
/// │ │   4   ││  5  ││     6     │       │
/// │ └───────┘└─────┘└───────────┘       │
/// └─────────────────────────────────────┘
/// ```
public struct Flow: Element {

    /// How to align each row when there is extra horizontal space.
    public var lineAlignment: LineAlignment

    /// Space between lines in the layout.
    public var lineSpacing: CGFloat

    /// How to align items in a line when there is extra vertical space.
    public var itemAlignment: ItemAlignment

    /// Space between items within a line.
    public var itemSpacing: CGFloat

    /// The child elements of the flow layout to be laid out.
    public var children: [Child]

    /// Creates a new flow layout with the provided parameters.
    public init(
        lineAlignment: LineAlignment = .leading,
        lineSpacing: CGFloat = 0,
        itemAlignment: ItemAlignment = .center,
        itemSpacing: CGFloat = 0,
        @ElementBuilder<Flow.Child> _ children: () -> [Flow.Child]
    ) {
        self.lineAlignment = lineAlignment
        self.lineSpacing = lineSpacing
        self.itemAlignment = itemAlignment
        self.itemSpacing = itemSpacing

        self.children = children()
    }

    // MARK: Element

    public var content: ElementContent {
        .init(
            layout: Layout(
                lineAlignment: lineAlignment,
                lineSpacing: lineSpacing,
                itemAlignment: itemAlignment,
                itemSpacing: itemSpacing
            )
        ) {
            for child in children {
                $0.add(traits: child.traits, key: child.key, element: child.element)
            }
        }
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
}

extension Flow {

    /// How to horizontally align the line when there is extra space.
    public enum LineAlignment: CaseIterable {

        /// Items are aligned with the leading edge.
        case leading

        /// Items are centered within the remaining space.
        case center

        /// Items are aligned with the trailing edge.
        case trailing
    }

    /// How to vertically align items which there is extra space.
    public enum ItemAlignment: CaseIterable {

        /// Shorter items are stretched to fill the height of the tallest item.
        case fill

        /// Shorter items are aligned to the top of the row.
        case top

        /// Shorter items are vertically aligned within the row.
        case center

        /// Shorter items are aligned to the bottom of the row.
        case bottom
    }

    /// A child placed within the flow layout.
    public struct Child: ElementBuilderChild {

        /// The key used to optionally unique the child item.
        public var key: AnyHashable?

        /// The traits of a child item.
        public var traits: Traits

        /// The element representing the child item.
        public var element: Element

        /// Creates a new child item with the given element.
        public init(_ element: Element) {
            key = nil
            traits = .init()
            self.element = element
        }

        /// Creates a new child item with the given element.
        public init(_ element: Element, key: AnyHashable? = nil) {
            self.key = key
            traits = .init()
            self.element = element
        }

        public struct Traits {}
    }
}


extension Element {

    /// Wraps the element in a `Flow.Child` to allow customizing the item in the flow layout.
    public func flowChild(key: AnyHashable? = nil) -> Flow.Child {
        .init(self, key: key)
    }
}


extension Flow {

    fileprivate struct Layout: BlueprintUI.Layout {

        typealias Traits = Child.Traits

        var lineAlignment: LineAlignment
        var lineSpacing: CGFloat
        var itemAlignment: ItemAlignment
        var itemSpacing: CGFloat

        static var defaultTraits: Traits = .init()

        // MARK: Caffeinated Layout

        func sizeThatFits(
            proposal: SizeConstraint,
            subelements: Subelements,
            environment: Environment,
            cache: inout ()
        ) -> CGSize {
            size(
                for: subelements.map { $0.sizeThatFits(_:) },
                in: proposal
            )
        }

        func placeSubelements(
            in size: CGSize,
            subelements: Subelements,
            environment: Environment,
            cache: inout ()
        ) {
            zip(
                frames(
                    for: subelements.map { $0.sizeThatFits(_:) },
                    in: .init(size)
                ),
                subelements
            ).forEach { frame, element in
                element.place(at: frame.origin, size: frame.size)
            }
        }

        typealias ElementSize = (SizeConstraint) -> CGSize

        private func frames(
            for elements: [ElementSize],
            in constraint: SizeConstraint
        ) -> [CGRect] {

            var totalHeight: CGFloat = 0
            var frames: [CGRect] = []
            var row = rowLayout(
                origin: .zero,
                maxWidth: constraint.maximum.width
            )

            for element in elements {

                let elementSize: CGSize = {
                    let size = element(constraint)

                    return CGSize(
                        width: min(size.width, constraint.width.maximum),
                        height: min(size.height, constraint.height.maximum)
                    )
                }()

                // Note: We always want at least one item per row.
                if !row.canFitItem(of: elementSize) && row.items.isEmpty == false {
                    frames += row.itemFrames()

                    totalHeight += row.height + lineSpacing

                    row = rowLayout(
                        origin: totalHeight,
                        maxWidth: constraint.maximum.width
                    )
                }

                row.addItem(of: elementSize)
            }

            return frames + row.itemFrames()
        }

        private func size(
            for elements: [ElementSize],
            in constraint: SizeConstraint
        ) -> CGSize {
            frames(
                for: elements,
                in: constraint
            ).reduce(.zero) { reduced, current in
                CGSize(
                    width: max(current.maxX, reduced.width),
                    height: max(reduced.height, current.maxY)
                )
            }
        }

        // MARK: Legacy Layout

        func measure(
            in constraint: SizeConstraint,
            items: [(
                traits: Traits,
                content: Measurable
            )]
        ) -> CGSize {
            size(
                for: items.map { $0.content.measure(in:) },
                in: constraint
            )
        }

        func layout(
            size: CGSize,
            items: [(
                traits: Traits,
                content: Measurable
            )]
        ) -> [LayoutAttributes] {
            frames(
                for: items.map { $0.content.measure(in:) },
                in: .init(size)
            ).map(LayoutAttributes.init(frame:))
        }

        // MARK: Private Methods

        private func rowLayout(
            origin: CGFloat,
            maxWidth: CGFloat
        ) -> RowLayout {
            .init(
                origin: origin,
                maxWidth: maxWidth,
                itemSpacing: itemSpacing,
                lineAlignment: lineAlignment,
                itemAlignment: itemAlignment
            )
        }
    }
}

// MARK: - RowLayout

extension Flow.Layout {

    /// Helper for computing the frames for a row of items.
    fileprivate struct RowLayout {

        let origin: CGFloat
        let maxWidth: CGFloat
        let itemSpacing: CGFloat
        let lineAlignment: Flow.LineAlignment
        let itemAlignment: Flow.ItemAlignment

        init(
            origin: CGFloat,
            maxWidth: CGFloat,
            itemSpacing: CGFloat,
            lineAlignment: Flow.LineAlignment,
            itemAlignment: Flow.ItemAlignment
        ) {
            self.origin = origin
            self.maxWidth = maxWidth
            self.itemSpacing = itemSpacing
            self.lineAlignment = lineAlignment
            self.itemAlignment = itemAlignment
        }

        private(set) var height: CGFloat = 0
        private(set) var items: [Item] = []
        private var totalItemWidth: CGFloat = 0

        struct Item {
            let size: CGSize
            let xOffset: CGFloat
        }

        /// `True` if we can fit an item of the given size in the row.
        func canFitItem(
            of size: CGSize
        ) -> Bool {
            CGFloat(items.count) * itemSpacing + totalItemWidth + size.width <= maxWidth
        }

        /// Adds item of given size to the row layout.
        mutating func addItem(of size: CGSize) {
            items.append(
                .init(
                    size: size,
                    xOffset: totalItemWidth + itemSpacing * CGFloat(items.count)
                )
            )
            totalItemWidth += size.width
            height = max(size.height, height)
        }

        /// Compute frames for the items in the row layout.
        func itemFrames() -> [CGRect] {
            let totalSpacing = (CGFloat(items.count) - 1) * itemSpacing
            let extraWidth = maxWidth - totalItemWidth - totalSpacing
            let firstItemX: CGFloat = {
                switch lineAlignment {
                case .center: extraWidth / 2.0
                case .trailing: extraWidth
                case .leading: 0.0
                }
            }()

            return items.map { item in
                .init(
                    x: firstItemX + item.xOffset,
                    y: {
                        switch itemAlignment {
                        case .fill: origin
                        case .top: origin
                        case .center: origin + (height - item.size.height) / 2
                        case .bottom: origin + (height - item.size.height)
                        }
                    }(),
                    width: item.size.width,
                    height: {
                        switch itemAlignment {
                        case .fill: height
                        case .top, .center, .bottom: item.size.height
                        }
                    }()
                )
            }
        }
    }
}
