import UIKit

/// Conforming types (Row and Column) act as StackLayout powered containers.
///
/// This protocol should only be used by Row and Column elements (you should never add conformance to other custom
/// types).
public protocol StackElement: Element {
    init()
    var layout: StackLayout { get }
    var children: [(element: Element, traits: StackLayout.Traits, key: AnyHashable?)] { get set }
}

extension StackElement {

    public var content: ElementContent {
        ElementContent(layout: layout) {
            for child in self.children {
                $0.add(traits: child.traits, key: child.key, element: child.element)
            }
        }
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }

}

extension StackElement {

    public init(_ configure: (inout Self) -> Void) {
        self.init()
        configure(&self)
    }

    /// Initializer using result builder to declaratively build up a stack.
    /// - Parameters:
    ///   - elementsBuilder: A block containing all elements to be included in the stack.
    /// - Note: If element is a StackLayout.Child, then traits and key will be pulled from the element, otherwise defaults are passed through.
    init(@ElementBuilder<StackLayout.Child> elementsBuilder: () -> [StackLayout.Child]) {
        self.init()
        children = elementsBuilder().map { stackLayoutChild in
            (stackLayoutChild.element, stackLayoutChild.traits, stackLayoutChild.key)
        }
    }

    /// Adds a given child element to the stack.
    ///
    /// - parameters:
    ///   - growPriority:
    ///
    ///     If the layout underflows (there is extra space to be distributed) and the layout's
    ///     underflow distribution is set to either `growProportionally` or `growUniformly`,
    ///     additional space will be given to children within the layout. `growPriority` is used to
    ///     customize how much of that additional space should be given to a particular child.
    ///
    ///     The default value is 1.0
    ///
    ///     The algorithm for distributing space is functionally equal to the following:
    ///
    ///     ```
    ///     let totalGrowPriority: CGFloat = /// The sum of the grow priority from all children
    ///     let totalUnderflowSize: CGFloat = /// The extra space to be distributed
    ///     for child in children {
    ///         let extraSize = (child.growPriority / totalGrowPriority) * totalUnderflowSize
    ///         /// `extraSize` is then added to the original measured size
    ///     }
    ///     ```
    ///
    ///   - shrinkPriority:
    ///
    ///     If the layout overflows (there is not enough space to fit all children as measured),
    ///     each child will receive a smaller size within the layout. `shrinkPriority` is used to
    ///     customize how much each child should shrink.
    ///
    ///     The default value is 1.0
    ///
    ///     The algorithm for removing space is functionally equal to the following:
    ///
    ///     ```
    ///     let totalShrinkPriority: CGFloat = /// The sum of the shrink priority from all children
    ///     let totalOverflowSize: CGFloat = /// The overflow space to be subtracted
    ///     for child in children {
    ///         let shrinkSize = (child.shrinkPriority / totalShrinkPriority) * totalOverflowSize
    ///         /// `extraSize` is then subtracted from the original measured size
    ///     }
    ///     ```
    ///
    ///   - alignmentGuide:
    ///
    ///     A closure that can be used to provide a custom alignment guide for this child.
    ///
    ///     This closure will be called with an `ElementDimensions` containing the dimensions of
    ///     this child, and should return a value in the child's own coordinate space. This value
    ///     represents the position along the child's cross axis that should be aligned relative to
    ///     the values of its siblings.
    ///
    ///     If not specified, the default value is provided by the stack's alignment.
    ///
    ///     The alignment guide is ignored by the `fill` alignment type.
    ///
    ///   - key: A key used to disambiguate children between subsequent updates of the view
    ///     hierarchy
    ///
    ///   - child: The child element to add to this stack
    ///
    /// - Tag: StackElement.add
    ///
    public mutating func add(
        growPriority: CGFloat = 1.0,
        shrinkPriority: CGFloat = 1.0,
        alignmentGuide: ((ElementDimensions) -> CGFloat)? = nil,
        key: AnyHashable? = nil,
        child: Element
    ) {
        children.append((
            element: child,
            traits: StackLayout.Traits(
                growPriority: growPriority,
                shrinkPriority: shrinkPriority,
                alignmentGuide: alignmentGuide.map(StackLayout.AlignmentGuide.init)
            ),
            key: key
        ))
    }


    /// Convenience method for adding a child with a grow and shrink priority of 0.0.
    ///
    /// See `StackElement.add(...)` for details.
    ///
    /// - parameters:
    ///   - alignmentGuide: A closure that can be used to provide a custom alignment guide for this
    ///     child.
    ///   - key: A key used to disambiguate children between subsequent updates of the view
    ///     hierarchy
    ///   - child: The child element to add to this stack
    ///
    /// ## In Xcode
    /// [StackElement.add()](x-source-tag://StackElement.add)
    ///
    public mutating func addFixed(
        alignmentGuide: ((ElementDimensions) -> CGFloat)? = nil,
        key: AnyHashable? = nil,
        child: Element
    ) {
        add(
            growPriority: 0,
            shrinkPriority: 0,
            alignmentGuide: alignmentGuide,
            key: key,
            child: child
        )
    }

    /// Convenience method for adding a child with a grow and shrink priority of 1.0.
    ///
    /// See `StackElement.add(...)` for details.
    ///
    /// - parameters:
    ///   - alignmentGuide: A closure that can be used to provide a custom alignment guide for this
    ///     child.
    ///   - key: A key used to disambiguate children between subsequent updates of the view
    ///     hierarchy
    ///   - child: The child element to add to this stack
    ///
    /// ## In Xcode
    /// [StackElement.add()](x-source-tag://StackElement.add)
    ///
    public mutating func addFlexible(
        alignmentGuide: ((ElementDimensions) -> CGFloat)? = nil,
        key: AnyHashable? = nil,
        child: Element
    ) {
        add(
            growPriority: 1,
            shrinkPriority: 1,
            alignmentGuide: alignmentGuide,
            key: key,
            child: child
        )
    }
}


/// A layout implementation that linearly lays out an array of children along either the horizontal or vertical axis.
public struct StackLayout: Layout {

    /// The default traits for a child contained within a stack layout
    public static var defaultTraits: Traits {
        Traits()
    }

    /// Determines how a stack child will be aligned on the cross axis relative to other children.
    public struct AlignmentGuide {
        /// Returns a value along the stack's cross axis, in the element's own coordinate space,
        /// where a child should be aligned relative to the alignment guides of its siblings.
        public var computeValue: (ElementDimensions) -> CGFloat
    }

    /// Contains traits that affect the layout of individual children in the stack.
    ///
    /// See `StackElement.add(...)` for details.
    ///
    /// # In Xcode
    /// [StackElement.add()](x-source-tag://StackElement.add)
    ///
    public struct Traits {

        /// Controls the amount of extra space distributed to this child during underflow.
        ///
        /// See `StackElement.add(...)` for details.
        ///
        /// # In Xcode
        /// [StackElement.add()](x-source-tag://StackElement.add)
        ///
        public var growPriority: CGFloat

        /// Controls the amount of space allowed for this child during overflow.
        ///
        /// See `StackElement.add(...)` for details.
        ///
        /// # In Xcode
        /// [StackElement.add()](x-source-tag://StackElement.add)
        ///
        public var shrinkPriority: CGFloat

        /// Allows for custom alignment of a child along the cross axis.
        ///
        /// See `StackElement.add(...)` for details.
        ///
        /// # In Xcode
        /// [StackElement.add()](x-source-tag://StackElement.add)
        ///
        public var alignmentGuide: AlignmentGuide?

        /// Creates a new set of traits with default values.
        public init(
            growPriority: CGFloat = 1.0,
            shrinkPriority: CGFloat = 1.0,
            alignmentGuide: AlignmentGuide? = nil
        ) {
            self.growPriority = growPriority
            self.shrinkPriority = shrinkPriority
            self.alignmentGuide = alignmentGuide
        }
    }

    public var axis: Axis

    public var underflow = UnderflowDistribution.spaceEvenly
    public var overflow = OverflowDistribution.condenseProportionally
    public var alignment: Alignment
    public var minimumSpacing: CGFloat = 0


    public init(axis: Axis, alignment: Alignment) {
        self.axis = axis
        self.alignment = alignment
    }

    public func measure(in constraint: SizeConstraint, items: [(traits: Traits, content: Measurable)]) -> CGSize {
        let size = _measureIn(constraint: constraint, items: items)
        return size
    }

    public func layout(size: CGSize, items: [(traits: Traits, content: Measurable)]) -> [LayoutAttributes] {
        _layout(size: size, items: items)
    }

}


extension StackLayout {

    /// The direction of the stack.
    public enum Axis {
        case horizontal
        case vertical
    }

    /// Determines the on-axis layout when there is extra free space available.
    public enum UnderflowDistribution {

        /// Additional space will be evenly divided into the spacing between items.
        case spaceEvenly

        /// Additional space will be divided proportionally by the measured size of each child.
        case growProportionally

        /// Additional space will be distributed uniformly between children.
        case growUniformly

        /// Additional space will appear after all children.
        case justifyToStart

        /// Additional space will be distributed on either side of all children.
        case justifyToCenter

        /// Additional space will be appear before all children.
        case justifyToEnd
    }

    /// Determines the on-axis layout when there is not enough space to fit all children as measured.
    public enum OverflowDistribution {

        /// Each child will shrink proportionally to its measured size.
        case condenseProportionally

        /// Each child will shrink by the same amount.
        case condenseUniformly
    }

    /// Determines the cross-axis layout (height for a horizontal stack, width for a vertical stack).
    public enum Alignment {
        /// Children will be stretched to the size of the stack.
        case fill
        /// Children will be aligned relatively to each other, and then all the contents will be
        /// aligned to the stack's bounding box, according to the specified alignment.
        case align(to: AlignmentID.Type)
    }

}

// MARK: - Layout logic

// Stack layout is generalized to work for both Rows and Columns.
//
// Some special terminology is used to symbolically represent the two axes of a stack:
//
//   - The axis along which elements are being laid out is generally called "axis".
//   - The other axis is the cross axis, or just "cross".
//
// For Rows, the axis is horizontal and the cross is vertical.
// For Columns, the axis is vertical and the cross is horizontal.
//
// Row──────────────────────────────────┐
// │┌───────┐                      ▲    │
// ││       │┌───────┐         ┌───┼───┐│
// ││       ││       │         │   │   ││
// ││       ││       │┌───────┐│ Cross ││
// ││       ││       ││       ││   │   ││
// │◀───────┼┼─────Axis───────┼┼───┼───▶│
// ││       ││       ││       ││   │   ││
// ││       ││       │└───────┘│   │   ││
// ││       ││       │         │   │   ││
// ││       │└───────┘         └───┼───┘│
// │└───────┘                      ▼    │
// └────────────────────────────────────┘
//
//      Column────────────────────┐
//      │┌───────────▲───────────┐│
//      ││           │           ││
//      ││         Axis          ││
//      ││           │           ││
//      │└───────────┼───────────┘│
//      │   ┌────────┼────────┐   │
//      │   │        │        │   │
//      │◀──┼────────┼─Cross──┼──▶│
//      │   │        │        │   │
//      │   └────────┼────────┘   │
//      │       ┌────┼────┐       │
//      │       │    │    │       │
//      │       │    │    │       │
//      │       │    │    │       │
//      │       └────┼────┘       │
//      │   ┌────────┼────────┐   │
//      │   │        │        │   │
//      │   │        │        │   │
//      │   │        │        │   │
//      │   └────────▼────────┘   │
//      └─────────────────────────┘
//
extension StackLayout {

    private func _layout(size: CGSize, items: [(traits: Traits, content: Measurable)]) -> [LayoutAttributes] {
        guard items.count > 0 else { return [] }

        // During layout the constraints are always `.exactly` to fit the provided size
        let vectorConstraint = size.vectorConstraint(axis: axis)

        let frames = _frames(for: items.map(StackLayoutItem.init), in: vectorConstraint)

        return frames.map { frame in
            LayoutAttributes(frame: frame.rect(axis: axis))
        }
    }

    private func _measureIn(constraint: SizeConstraint, items: [(traits: Traits, content: Measurable)]) -> CGSize {
        guard items.count > 0 else { return .zero }

        // During measurement the constraints may be `.atMost` or `.unconstrained` to fit the measurement constraint
        let vectorConstraint = constraint.vectorConstraint(on: axis)

        let frames = _frames(for: items.map(StackLayoutItem.init), in: vectorConstraint)

        let vector = frames.reduce(Vector.zero) { vector, frame -> Vector in
            Vector(
                axis: max(vector.axis, frame.maxAxis),
                cross: max(vector.cross, frame.maxCross)
            )
        }

        return vector.size(axis: axis)
    }

    private func _frames(
        for items: [StackLayoutItem],
        in vectorConstraint: VectorConstraint
    ) -> [VectorFrame] {
        // First allocate available space along the layout axis.
        let axisSegments = _axisSegments(for: items, in: vectorConstraint)

        let axisConstraints = axisSegments.map { $0.magnitude }

        // Then measure cross axis for each item based on the space it was allocated.
        let crossSegments = _crossSegments(
            for: items,
            axisConstraints: axisConstraints,
            crossConstraint: vectorConstraint.cross
        )

        // Finally, merge axis and cross segments into frames.
        return zip(axisSegments, crossSegments).map(VectorFrame.init(axis:cross:))
    }

    /// Measures the given items under the given constraint, and returns their
    /// sizes along the layout axis, represented as segments.
    ///
    /// The axis segments of a Row look like this diagram.
    ///
    /// Row───────────────────────────────────────────┐
    /// │┌───────────┐                                │
    /// ││           │                   ┌───────────┐│
    /// ││           │┌─────────────────┐│           ││
    /// │◀───────────┼┼──────Axis───────┼┼───────────▶│
    /// ││           ││                 ││           ││
    /// ││■─segment─▶││■────segment────▶││■─segment─▶││
    /// ││           ││                 ││           ││
    /// ││           ││                 ││           ││
    /// ││           │└─────────────────┘│           ││
    /// ││           │                   └───────────┘│
    /// │└───────────┘                                │
    /// └─────────────────────────────────────────────┘
    ///
    /// - Parameters:
    ///   - for: The items to measure.
    ///   - in: The constraint for all measurements.
    /// - Returns: The axis measurements as segments.
    private func _axisSegments(
        for items: [StackLayoutItem],
        in vectorConstraint: VectorConstraint
    ) -> [Segment] {

        let minimumTotalSpacing = CGFloat(items.count - 1) * minimumSpacing

        func basisSizes() -> [CGFloat] {
            let constraint = vectorConstraint.constraint(axis: axis)

            final class Measurement {

                let item: StackLayoutItem
                var size: CGSize?

                let isFixed: Bool

                var isFlexible: Bool {
                    isFixed == false
                }

                init(item: StackLayoutItem) {
                    self.item = item
                    size = nil

                    isFixed = item.traits.growPriority == 0 && item.traits.shrinkPriority == 0
                }
            }

            let measurements: [Measurement] = items.map { item in
                Measurement(item: item)
            }

            // Measure fixed items

            measurements.forEach { measurement in
                guard measurement.isFixed else { return }

                measurement.size = measurement.item
                    .measure(in: constraint)
            }

            // Determine how much space the fixed items took up

            let fixedMagnitude: CGFloat = measurements.reduce(0) { magnitude, measurement in
                magnitude + (measurement.size?.axis(on: axis) ?? 0)
            }

            // From that, determine how much space the flexible items will have

            let flexibleMagnitude: SizeConstraint.Axis = constraint.axis(on: axis) - fixedMagnitude - minimumTotalSpacing

            if flexibleMagnitude.isGreaterThanZero {
                let flexibleConstraint: SizeConstraint = {
                    switch axis {
                    case .horizontal:
                        return .init(width: flexibleMagnitude, height: constraint.height)
                    case .vertical:
                        return .init(width: constraint.width, height: flexibleMagnitude)
                    }
                }()

                // Measure the flexible items within that constraint
                measurements.forEach { measurement in
                    guard measurement.isFlexible else { return }

                    measurement.size = measurement
                        .item
                        .measure(in: flexibleConstraint)
                }
            } else {
                // The fixed items in the stack take up all of the available size,
                // so we can't meaningfully measure anything. Just set the size to zero.
                measurements.forEach { measurement in
                    guard measurement.isFlexible else { return }

                    measurement.size = .zero
                }
            }

            return measurements.map { $0.size!.axis(on: axis) }
        }

        let basisSizes = basisSizes()

        func unconstrainedAxisSize() -> CGFloat {
            basisSizes.reduce(0.0, +) + minimumTotalSpacing
        }

        switch vectorConstraint.axis {
        case .exactly(let axisSize):
            if unconstrainedAxisSize() >= axisSize {
                // Overflow: compress to axis constraint
                return _layoutOverflow(
                    basisSizes: basisSizes,
                    traits: items.map { $0.traits },
                    layoutSize: axisSize
                )
            } else {
                // Underflow: expand to axis constraint
                return _layoutUnderflow(
                    basisSizes: basisSizes,
                    traits: items.map { $0.traits },
                    layoutSize: axisSize
                )
            }

        case .atMost(let axisMax):
            if unconstrainedAxisSize() >= axisMax {
                // Overflow: compress to axis constraint
                return _layoutOverflow(
                    basisSizes: basisSizes,
                    traits: items.map { $0.traits },
                    layoutSize: axisMax
                )
            } else {
                // Underflow: allow to fit natural size
                return _layoutUnconstrained(basisSizes: basisSizes)
            }

        case .unconstrained:
            return _layoutUnconstrained(basisSizes: basisSizes)
        }
    }

    private func _layoutUnconstrained(basisSizes: [CGFloat]) -> [Segment] {
        var nextOrigin: CGFloat = 0

        return basisSizes.map { size -> Segment in
            let origin = nextOrigin
            let magnitude = size

            nextOrigin = origin + magnitude + minimumSpacing

            return Segment(origin: origin, magnitude: magnitude)
        }
    }

    private func _layoutOverflow(basisSizes: [CGFloat], traits: [Traits], layoutSize: CGFloat) -> [Segment] {
        assert(basisSizes.count > 0)

        let totalBasisSize: CGFloat = basisSizes.reduce(0.0, +)
        let totalSpacing = minimumSpacing * CGFloat(basisSizes.count - 1)

        /// The overflow size that will be distributed among children
        let extraSize: CGFloat = layoutSize - (totalBasisSize + totalSpacing)

        assert(extraSize <= 0.0)

        var shrinkPriorities: [CGFloat] = []

        for index in 0..<basisSizes.count {
            let basis = basisSizes[index]
            let traits = traits[index]
            var priority: CGFloat
            switch overflow {
            case .condenseProportionally:
                if totalBasisSize > 0 {
                    priority = basis / totalBasisSize
                } else {
                    priority = basis
                }
            case .condenseUniformly:
                priority = 1.0
            }

            priority *= traits.shrinkPriority
            shrinkPriorities.append(priority)
        }

        var totalPriority: CGFloat = shrinkPriorities.reduce(0, +)
        if totalPriority == 0 {
            totalPriority = 1
        }

        var axisOrigin: CGFloat = 0.0

        let axisSegments = zip(basisSizes, shrinkPriorities).map { basis, shrinkPriority -> Segment in
            let sizeAdjustment = (shrinkPriority / totalPriority) * extraSize
            let magnitude = max(0, basis + sizeAdjustment)
            let origin = axisOrigin

            axisOrigin = origin + magnitude + minimumSpacing

            return Segment(origin: origin, magnitude: magnitude)
        }

        return axisSegments
    }

    private func _layoutUnderflow(basisSizes: [CGFloat], traits: [Traits], layoutSize: CGFloat) -> [Segment] {
        assert(basisSizes.count > 0)

        let totalBasisSize: CGFloat = basisSizes.reduce(0.0, +)

        let minimumTotalSpace = minimumSpacing * CGFloat(basisSizes.count - 1)
        /// The underflow size that will be distributed among children
        let extraSize: CGFloat = layoutSize - (totalBasisSize + minimumTotalSpace)

        assert(extraSize >= 0.0)

        let space: CGFloat

        switch underflow {
        case .growProportionally:
            space = minimumSpacing
        case .growUniformly:
            space = minimumSpacing
        case .spaceEvenly:
            space = (layoutSize - totalBasisSize) / CGFloat(basisSizes.count - 1)
        case .justifyToStart:
            space = minimumSpacing
        case .justifyToCenter:
            space = minimumSpacing
        case .justifyToEnd:
            space = minimumSpacing
        }

        var axisOrigin: CGFloat

        switch underflow {
        case .growProportionally:
            axisOrigin = 0.0
        case .growUniformly:
            axisOrigin = 0.0
        case .spaceEvenly:
            axisOrigin = 0.0
        case .justifyToStart:
            axisOrigin = 0.0
        case .justifyToCenter:
            axisOrigin = extraSize / 2.0
        case .justifyToEnd:
            axisOrigin = extraSize
        }

        var growPriorities: [CGFloat] = []

        for index in 0..<basisSizes.count {
            let basis = basisSizes[index]
            let traits = traits[index]
            var priority: CGFloat
            switch underflow {
            case .growProportionally:
                if totalBasisSize > 0 {
                    priority = basis / totalBasisSize
                } else {
                    priority = basis
                }
            case .growUniformly:
                priority = 1.0
            case .spaceEvenly:
                priority = 0.0
            case .justifyToStart:
                priority = 0.0
            case .justifyToCenter:
                priority = 0.0
            case .justifyToEnd:
                priority = 0.0
            }

            priority *= traits.growPriority
            growPriorities.append(priority)
        }

        var totalPriority: CGFloat = growPriorities.reduce(0, +)
        if totalPriority == 0 {
            totalPriority = 1
        }

        let axisSegments = zip(basisSizes, growPriorities).map { basis, growPriority -> Segment in
            let sizeAdjustment = (growPriority / totalPriority) * extraSize
            let origin = axisOrigin
            let magnitude = max(0, basis + sizeAdjustment)

            axisOrigin = origin + magnitude + space

            return Segment(origin: origin, magnitude: magnitude)
        }

        return axisSegments
    }

    /// Measures the given items and returns their sizes along the cross axis,
    /// represented as segments. Each item is constrained by a different value
    /// along the axis.
    ///
    /// The cross segments of a Row look like this diagram.
    ///
    /// Row───────────────────────────────────────────┐
    /// │┌───────────┐    ▲                           │
    /// ││     ■     │    │              ┌───────────┐│
    /// ││     │     │┌───┼─────────────┐│     ■     ││
    /// ││     │     ││ Cross  ■        ││     │     ││
    /// ││     │     ││   │    │        ││     │     ││
    /// ││  segment  ││   │ segment     ││  segment  ││
    /// ││     │     ││   │    │        ││     │     ││
    /// ││     │     ││   │    ▼        ││     │     ││
    /// ││     │     │└───┼─────────────┘│     ▼     ││
    /// ││     ▼     │    │              └───────────┘│
    /// │└───────────┘    ▼                           │
    /// └─────────────────────────────────────────────┘
    ///
    /// - Parameters:
    ///   - for: The items to measure.
    ///   - axisConstraints: The axis components of the constraint for each measurement.
    ///   - crossConstraint: The cross component of the constraint for all measurements.
    /// - Returns: The cross measurements as segments.
    private func _crossSegments(
        for items: [StackLayoutItem],
        axisConstraints: [CGFloat],
        crossConstraint: VectorConstraint.Axis
    ) -> [Segment] {
        // Measures cross magnitudes based on axis constraints
        func measureMagnitudes() -> [CGFloat] {
            zip(items, axisConstraints).map { item, axisConstraint -> CGFloat in
                let vector = VectorConstraint(
                    axis: .atMost(axisConstraint),
                    cross: crossConstraint
                )
                let constraint = vector.constraint(axis: axis)
                let measuredSize = item.measure(in: constraint)

                return measuredSize.cross(on: axis)
            }
        }

        func fillSegments() -> [Segment] {
            // Determine the available cross based on the constraint
            let availableCross: CGFloat
            switch crossConstraint {
            case .unconstrained:
                let crossMagnitudes = measureMagnitudes()
                availableCross = crossMagnitudes.reduce(0, max)
            case .exactly(let exactConstraint):
                availableCross = exactConstraint
            case .atMost(let maxConstraint):
                let crossMagnitudes = measureMagnitudes()
                let maxMagnitude = crossMagnitudes.reduce(0, max)
                availableCross = min(maxConstraint, maxMagnitude)
            }

            // Form segments that fill the available space
            let segments = Array(
                repeating: Segment(origin: 0, magnitude: availableCross),
                count: items.count
            )

            return segments
        }

        func alignSegments(to alignment: AlignmentID.Type) -> [Segment] {
            let crossMagnitudes = measureMagnitudes()

            // Get the alignment values for each child
            let alignmentValues = items.indices.map { i -> CGFloat in
                let measuredCross = crossMagnitudes[i]
                let axisSize = axisConstraints[i]

                let size = Vector(axis: axisSize, cross: measuredCross).size(axis: axis)
                let dimensions = ElementDimensions(size: size)
                let alignmentGuide = items[i].traits.alignmentGuide

                let value = alignmentGuide?.computeValue(dimensions) ?? alignment.defaultValue(in: dimensions)

                return value
            }

            // Find the relative distance from the "lowest" edge to the "highest" edge.
            // This may be greater than the size of any single child, if alignment values push
            // children outside of their normal bounds.

            let minAlignedCross = -alignmentValues.max()!
            let maxAlignedCross = zip(crossMagnitudes, alignmentValues).map(-).max()!
            let normalizedCrossMagnitude = maxAlignedCross - minAlignedCross

            // Determine the available cross based on the constraint
            let availableCross: CGFloat
            switch crossConstraint {
            case .unconstrained:
                availableCross = normalizedCrossMagnitude
            case .exactly(let exactConstraint):
                availableCross = exactConstraint
            case .atMost(let maxConstraint):
                availableCross = min(maxConstraint, normalizedCrossMagnitude)
            }

            let availableAxis = axisConstraints.reduce(0, +)
            let availableSize = Vector(axis: availableAxis, cross: availableCross).size(axis: axis)
            let contentsSize = Vector(axis: availableAxis, cross: normalizedCrossMagnitude).size(axis: axis)

            // Align the contents as a whole within the stack, which may be larger or smaller than
            // the relatively aligned contents.
            let stackAnchor = alignment.defaultValue(in: ElementDimensions(size: availableSize))
            let contentsAnchor = alignment.defaultValue(in: ElementDimensions(size: contentsSize))

            let offset = stackAnchor - contentsAnchor - minAlignedCross

            // Form segments from the alignment values and measured magnitudes
            let segments = items.indices.map { i -> Segment in
                let measuredCross = crossMagnitudes[i]
                let alignmentValue = alignmentValues[i]

                let origin = offset - alignmentValue

                return Segment(origin: origin, magnitude: measuredCross)
            }

            return segments
        }

        switch alignment {
        case .fill:
            return fillSegments()
        case let .align(to: id):
            return alignSegments(to: id)
        }
    }
}

extension LayoutSubelement {
    var stackLayoutTraits: StackLayout.Traits {
        traits(forLayoutType: StackLayout.self)
    }
}

extension StackLayout {
    public func sizeThatFits(
        proposal: SizeConstraint,
        subelements: Subelements,
        environment: Environment,
        cache: inout ()
    ) -> CGSize {
        guard subelements.isEmpty == false else { return .zero }

        let constraint = proposal.vectorConstraint(on: axis)

        let frames = _frames(for: subelements.map(StackLayoutItem.init), in: constraint)

        let vector = frames.reduce(Vector.zero) { vector, frame -> Vector in
            Vector(
                axis: max(vector.axis, frame.maxAxis),
                cross: max(vector.cross, frame.maxCross)
            )
        }

        return vector.size(axis: axis)
    }

    public func placeSubelements(
        in size: CGSize,
        subelements: Subelements,
        environment: Environment,
        cache: inout ()
    ) {
        let constraint = size.vectorConstraint(axis: axis)

        let frames = _frames(for: subelements.map(StackLayoutItem.init), in: constraint)

        for i in 0..<subelements.count {
            let vectorFrame = frames[i]
            let subelement = subelements[i]

            let frame = vectorFrame.rect(axis: axis)

            subelement.place(
                at: frame.origin,
                anchor: .topLeading,
                size: frame.size
            )
        }
    }

    private struct StackLayoutItem {

        let traits: Traits
        private let measure: (SizeConstraint) -> CGSize

        init(_ tuple: (Traits, Measurable)) {
            traits = tuple.0
            measure = tuple.1.measure(in:)
        }

        init(_ subelement: LayoutSubelement) {
            traits = subelement.stackLayoutTraits
            measure = subelement.sizeThatFits(_:)
        }

        func measure(in constraint: SizeConstraint) -> CGSize {
            measure(constraint)
        }
    }
}

// MARK: - Layout types

extension StackLayout {
    /// Represents an origin and size value in a single axis.
    struct Segment {
        var origin: CGFloat
        var magnitude: CGFloat
    }

    /// Represents a size or point with symbolic axes.
    struct Vector {
        static let zero = Vector(axis: 0, cross: 0)

        var axis: CGFloat
        var cross: CGFloat

        func size(axis: StackLayout.Axis) -> CGSize {
            switch axis {
            case .horizontal:
                return CGSize(width: self.axis, height: cross)
            case .vertical:
                return CGSize(width: cross, height: self.axis)
            }
        }

        func point(axis: StackLayout.Axis) -> CGPoint {
            switch axis {
            case .horizontal:
                return CGPoint(x: self.axis, y: cross)
            case .vertical:
                return CGPoint(x: cross, y: self.axis)
            }
        }
    }

    /// Represents a size constraint with symbolic axes
    struct VectorConstraint {
        enum Axis {
            case exactly(CGFloat)
            case atMost(CGFloat)
            case unconstrained

            var sizeConstraint: SizeConstraint.Axis {
                switch self {
                case .exactly(let max), .atMost(let max):
                    return .atMost(max)
                case .unconstrained:
                    return .unconstrained
                }
            }
        }

        var axis: Axis
        var cross: Axis

        func constraint(axis layoutAxis: StackLayout.Axis) -> SizeConstraint {
            switch layoutAxis {
            case .horizontal:
                return SizeConstraint(width: axis.sizeConstraint, height: cross.sizeConstraint)
            case .vertical:
                return SizeConstraint(width: cross.sizeConstraint, height: axis.sizeConstraint)
            }
        }
    }

    /// Represents a rectangle with symbolic axes
    struct VectorFrame {
        var origin: Vector
        var size: Vector

        init(axis: Segment, cross: Segment) {
            origin = Vector(axis: axis.origin, cross: cross.origin)
            size = Vector(axis: axis.magnitude, cross: cross.magnitude)
        }

        func rect(axis: StackLayout.Axis) -> CGRect {
            CGRect(origin: origin.point(axis: axis), size: size.size(axis: axis))
        }

        var maxAxis: CGFloat {
            origin.axis + size.axis
        }

        var minAxis: CGFloat {
            origin.axis
        }

        var maxCross: CGFloat {
            origin.cross + size.cross
        }

        var minCross: CGFloat {
            origin.cross
        }
    }
}

// MARK: - Extensions

extension CGSize {

    fileprivate func stackVector(axis: StackLayout.Axis) -> StackLayout.Vector {
        switch axis {
        case .horizontal:
            return StackLayout.Vector(axis: width, cross: height)
        case .vertical:
            return StackLayout.Vector(axis: height, cross: width)
        }
    }

    fileprivate func vectorConstraint(axis: StackLayout.Axis) -> StackLayout.VectorConstraint {
        switch axis {
        case .horizontal:
            return StackLayout.VectorConstraint(
                axis: .exactly(width),
                cross: .exactly(height)
            )
        case .vertical:
            return StackLayout.VectorConstraint(
                axis: .exactly(height),
                cross: .exactly(width)
            )
        }
    }

    fileprivate func axis(on axis: StackLayout.Axis) -> CGFloat {
        switch axis {
        case .horizontal:
            return width
        case .vertical:
            return height
        }
    }

    fileprivate func cross(on axis: StackLayout.Axis) -> CGFloat {
        switch axis {
        case .horizontal:
            return height
        case .vertical:
            return width
        }
    }
}

extension SizeConstraint {
    fileprivate func vectorConstraint(on axis: StackLayout.Axis) -> StackLayout.VectorConstraint {
        switch axis {
        case .horizontal:
            return StackLayout.VectorConstraint(axis: width.vectorConstraint, cross: height.vectorConstraint)
        case .vertical:
            return StackLayout.VectorConstraint(axis: height.vectorConstraint, cross: width.vectorConstraint)
        }
    }

    fileprivate func axis(on axis: StackLayout.Axis) -> SizeConstraint.Axis {
        switch axis {
        case .horizontal:
            return width
        case .vertical:
            return height
        }
    }

    fileprivate func cross(on axis: StackLayout.Axis) -> SizeConstraint.Axis {
        switch axis {
        case .horizontal:
            return height
        case .vertical:
            return width
        }
    }
}

extension SizeConstraint.Axis {
    fileprivate var vectorConstraint: StackLayout.VectorConstraint.Axis {
        switch self {
        case .atMost(let max):
            return .atMost(max)
        case .unconstrained:
            return .unconstrained
        }
    }
}

// MARK: - Result Builders

/// `StackLayout.Child` is a wrapper which holds an element along with  its StackLayout traits and Keys.
/// This struct is particularly useful when working with `@ElementBuilder<StackLayout.Child>`.
/// By default, elements inside of `ElementBuilder<StackLayout.Child>` will be implicitly converted to a StackLayout.Child
/// with a nil key and the default `StackLayout.Traits` initializer. But when given a `StackLayout.Child` via
/// `Element.StackLayout.Child(...)` modifier or initialized directly, `@ElementBuilder<StackLayout.Child>`
/// pull out the given traits and key and then apply those to the stack
extension StackLayout {
    public struct Child {
        public let element: Element
        public let traits: StackLayout.Traits
        public let key: AnyHashable?

        public enum Priority {
            /// The element has a fixed size, with a grow and shrink priority of 0.
            /// The element will neither grow nor shrink during overflow and underflow.
            case fixed

            /// The element has a flexible size, with a grow and shrink priority of 1.
            /// The element will grow during underflow and shrink during overflow.
            case flexible

            /// The element has a flexible size, it will grow if the stack underflows,
            /// but it will not shrink if the stack overflows.
            case grows

            /// The element has a flexible size, it will shrink if the stack overflows,
            /// but it will not grow if the stack underflows.
            case shrinks

            fileprivate var growPriority: CGFloat {
                switch self {
                case .fixed: return 0
                case .flexible: return 1
                case .grows: return 1
                case .shrinks: return 0
                }
            }

            fileprivate var shrinkPriority: CGFloat {
                switch self {
                case .fixed: return 0
                case .flexible: return 1
                case .grows: return 0
                case .shrinks: return 1
                }
            }
        }

        public init(
            element: Element,
            traits: StackLayout.Traits = .init(),
            key: AnyHashable? = nil
        ) {
            self.element = element
            self.traits = traits
            self.key = key
        }

        public init(
            element: Element,
            priority: Priority = .flexible,
            alignmentGuide: ((ElementDimensions) -> CGFloat)? = nil,
            key: AnyHashable? = nil
        ) {
            self.init(
                element: element,
                traits: .init(
                    growPriority: priority.growPriority,
                    shrinkPriority: priority.shrinkPriority,
                    alignmentGuide: alignmentGuide.map(StackLayout.AlignmentGuide.init)
                ),
                key: key
            )
        }
    }
}

extension Element {

    /// Wraps an element with a `StackLayout.Child` in order to customize `StackLayout.Traits` and the key.
    /// - Parameters:
    ///   - priority: Controls the amount of extra space distributed to this child during underflow and overflow
    ///   - alignmentGuide: Allows for custom alignment of a child along the cross axis.
    ///   - key: A key used to disambiguate children between subsequent updates of the view
    ///     hierarchy.
    /// - Returns: A wrapper containing this element with additional layout information for the `StackElement`.
    public func stackLayoutChild(
        priority: StackLayout.Child.Priority = .flexible,
        alignmentGuide: ((ElementDimensions) -> CGFloat)? = nil,
        key: AnyHashable? = nil
    ) -> StackLayout.Child {
        .init(
            element: self,
            priority: priority,
            alignmentGuide: alignmentGuide,
            key: key
        )
    }

    /// Wraps an element with a `StackLayout.Child` in order to customize the `StackLayout.Child.Priority`.
    /// - Parameters:
    ///   - priority: Controls the amount of extra space distributed to this child during underflow and overflow
    /// - Returns: A wrapper containing this element with additional layout information for the `StackElement`.
    public func stackLayoutChild(
        priority: StackLayout.Child.Priority
    ) -> StackLayout.Child {
        .init(
            element: self,
            priority: priority,
            alignmentGuide: nil,
            key: nil
        )
    }
}

/// Map `Keyed` elements in result builders to `StackLayout.Child`.
extension ElementBuilder where Child == StackLayout.Child {
    public static func buildExpression(_ keyed: Keyed) -> Children {
        [StackLayout.Child(element: keyed.wrapped, key: keyed.key)]
    }
}

extension StackLayout.Child: ElementBuilderChild {
    public init(_ element: Element) {
        self.init(element: element)
    }
}
