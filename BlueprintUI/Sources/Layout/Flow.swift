import UIKit


/// Element which lays out children horizontally, wrapping to another row when there is not enough space.
///
/// You may control the layout of each row within the flow layout, by providing a `HorizontalAlignment`,
/// which controls the horizontal alignment of content within a row when it is smaller than its container,
/// and via `RowAlignment`, which controls the vertical alignment of shorter elements within a row.
///
/// ```swift
/// Flow(horizontalSpacing: 10, rowSpacing: 10) {
///     OnboardingPill("Food / drink")
///     OnboardingPill("Retail goods")
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

    /// How to horizontally align items in the row when there is extra space.
    public var horizontalAlignment: HorizontalAlignment

    /// How to vertically align items which there is extra space.
    public var rowAlignment: RowAlignment

    /// Space between items within a row.
    public var horizontalSpacing: CGFloat

    /// Space between rows.
    public var rowSpacing: CGFloat

    /// The child elements of the flow layout to be laid out.
    public var children: [Child]

    /// Creates a new flow layout with the provided parameters.
    public init(
        horizontalAlignment: HorizontalAlignment = .leading,
        horizontalSpacing: CGFloat = 0,
        rowAlignment: RowAlignment = .center,
        rowSpacing: CGFloat = 0,
        @ElementBuilder<Flow.Child> _ children: () -> [Flow.Child]
    ) {
        self.horizontalAlignment = horizontalAlignment
        self.horizontalSpacing = horizontalSpacing
        self.rowAlignment = rowAlignment
        self.rowSpacing = rowSpacing
        self.children = children()
    }

    // MARK: Element

    public var content: ElementContent {
        .init(
            layout: Layout(
                horizontalAlignment: horizontalAlignment,
                rowAlignment: rowAlignment,
                horizontalSpacing: horizontalSpacing,
                rowSpacing: rowSpacing
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

    /// How to horizontally align items in the row when there is extra space.
    public enum HorizontalAlignment: CaseIterable {

        /// Items are aligned with the leading edge.
        case leading

        /// Items are centered within the remaining space.
        case center

        /// Items are aligned with the trailing edge.
        case trailing
    }

    /// How to vertically align items which there is extra space.
    public enum RowAlignment: CaseIterable {

        /// Shorter items are stretched to fill the height of the tallest item.
        case fill

        /// Shorter items are aligned to the top of the row.
        case top

        /// Shorter items are vertically aligned within the row.
        case center

        /// Shoter items are aligned to the bottom of the row.
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

        public struct Traits {}
    }
}

extension Flow {

    fileprivate struct Layout: BlueprintUI.Layout {

        typealias Traits = Child.Traits

        var horizontalAlignment: HorizontalAlignment
        var rowAlignment: RowAlignment
        var horizontalSpacing: CGFloat
        var rowSpacing: CGFloat

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
                let elementSize = element(constraint)

                if !row.canFitItem(of: elementSize) {
                    frames += row.itemFrames()

                    totalHeight += row.height + rowSpacing

                    row = rowLayout(
                        origin: .init(x: 0, y: totalHeight),
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
            origin: CGPoint,
            maxWidth: CGFloat
        ) -> RowLayout {
            .init(
                origin: origin,
                maxWidth: maxWidth,
                itemSpacing: horizontalSpacing,
                horizontalAlignment: horizontalAlignment,
                rowAlignment: rowAlignment
            )
        }
    }
}

// MARK: - RowLayout

extension Flow.Layout {

    /// Helper for computing the frames for a row of items.
    fileprivate struct RowLayout {

        let origin: CGPoint
        let maxWidth: CGFloat
        let itemSpacing: CGFloat
        let horizontalAlignment: Flow.HorizontalAlignment
        let rowAlignment: Flow.RowAlignment

        init(
            origin: CGPoint,
            maxWidth: CGFloat,
            itemSpacing: CGFloat,
            horizontalAlignment: Flow.HorizontalAlignment,
            rowAlignment: Flow.RowAlignment
        ) {
            self.origin = origin
            self.maxWidth = maxWidth
            self.itemSpacing = itemSpacing
            self.horizontalAlignment = horizontalAlignment
            self.rowAlignment = rowAlignment
        }

        private(set) var height: CGFloat = 0
        private var items: [Item] = []
        private var totalItemWidth: CGFloat = 0

        private var itemCount: CGFloat {
            CGFloat(items.count)
        }

        struct Item {
            let size: CGSize
            let xOffset: CGFloat
        }

        /// `True` if we can fit an item of the given size in the row.
        func canFitItem(
            of size: CGSize
        ) -> Bool {
            itemCount * itemSpacing + totalItemWidth + size.width <= maxWidth
        }

        /// Adds item of given size to the row layout.
        mutating func addItem(of size: CGSize) {
            items.append(
                .init(
                    size: size,
                    xOffset: totalItemWidth + itemSpacing * itemCount
                )
            )
            totalItemWidth += size.width
            height = max(size.height, height)
        }

        /// Compute frames for the items in the row layout.
        func itemFrames() -> [CGRect] {
            let totalSpacing = (itemCount - 1) * itemSpacing
            let extraWidth = maxWidth - totalItemWidth - totalSpacing
            let firstItemX: CGFloat = {
                switch horizontalAlignment {
                case .center: extraWidth / 2.0
                case .trailing: extraWidth
                case .leading: 0.0
                }
            }()

            return items.map { item in
                .init(
                    x: firstItemX + item.xOffset,
                    y: {
                        switch rowAlignment {
                        case .fill: origin.y
                        case .top: origin.y
                        case .center: origin.y + (height - item.size.height) / 2
                        case .bottom: origin.y + (height - item.size.height)
                        }
                    }(),
                    width: item.size.width,
                    height: {
                        switch rowAlignment {
                        case .fill: height
                        case .top, .center, .bottom: item.size.height
                        }
                    }()
                )
            }
        }
    }
}
