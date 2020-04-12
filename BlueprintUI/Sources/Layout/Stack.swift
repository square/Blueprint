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
                $0.add(
                    element: child.element,
                    traits: child.traits,
                    key: child.key
                )
            }
        }
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }

}

extension StackElement {

    public init(_ configure: (inout Self) -> Void) {
        self.init()
        configure(&self)
    }

    /// Adds a given child element to the stack.
    ///
    /// - parameters:
    ///   - growPriority: If the layout underflows (there is extra space to be distributed) and the layout's underflow distribution
    ///                   is set to either `growProportionally` or `growUniformly`, additional space will be given to children
    ///                   within the layout. `growPriority` is used to customize how much of that additional space should be given
    ///                   to a particular child.
    ///
    ///                   The default value is 1.0
    ///
    ///                   The algorithm for distributing space is functionally equal to the following:
    ///
    ///                   ```
    ///                   let totalGrowPriority: CGFloat = /// The sum of the grow priority from all children
    ///                   let totalUnderflowSize: CGFloat = /// The extra space to be distributed
    ///                   for child in children {
    ///                       let extraSize = (child.growPriority / totalGrowPriority) * totalUnderflowSize
    ///                       /// `extraSize` is then added to the original measured size
    ///                   }
    ///                   ```
    ///
    ///   - shrinkPriority: If the layout overflows (there is not enough space to fit all children as measured), each child will receive
    ///                     a smaller size within the layout. `shrinkPriority` is used to customize how much each child should shrink.
    ///
    ///                     The default value is 1.0
    ///
    ///                     The algorithm for removing space is functionally equal to the following:
    ///
    ///                     ```
    ///                     let totalShrinkPriority: CGFloat = /// The sum of the shrink priority from all children
    ///                     let totalOverflowSize: CGFloat = /// The overflow space to be subtracted
    ///                     for child in children {
    ///                         let shrinkSize = (child.shrinkPriority / totalShrinkPriority) * totalOverflowSize
    ///                         /// `extraSize` is then subtracted from the original measured size
    ///                     }
    ///                     ```
    ///
    ///   - key: A key used to disambiguate children between subsequent updates of the view hierarchy
    ///
    ///   - child: The child element to add to this stack
    ///
    mutating public func add(growPriority: CGFloat = 1.0, shrinkPriority: CGFloat = 1.0, key: AnyHashable? = nil, child: Element) {
        children.append((
            element: child,
            traits: StackLayout.Traits(growPriority: growPriority, shrinkPriority: shrinkPriority),
            key: key
        ))
    }

}


/// A layout implementation that linearly lays out an array of children along either the horizontal or vertial axis.
public struct StackLayout: Layout {

    /// The default traits for a child contained within a stack layout
    public static var defaultTraits: Traits {
        return Traits()
    }

    public struct Traits {

        public var growPriority: CGFloat

        public var shrinkPriority: CGFloat

        public init(growPriority: CGFloat = 1.0, shrinkPriority: CGFloat = 1.0) {
            self.growPriority = growPriority
            self.shrinkPriority = shrinkPriority
        }

    }

    public var axis: Axis

    public var underflow = UnderflowDistribution.spaceEvenly
    public var overflow = OverflowDistribution.condenseProportionally
    public var alignment = Alignment.leading
    public var minimumSpacing: CGFloat = 0


    public init(axis: Axis) {
        self.axis = axis
    }
    
    public func layout(in constraint : SizeConstraint, items: [LayoutItem<Self>]) -> LayoutResult {
        LayoutResult(
            size: {
                _measureIn(constraint: constraint, items: items)
            },
            layoutAttributes: {
                _layout(size: $0, items: items)
            }
        )
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
        case fill
        case leading
        case center
        case trailing
    }

}

// MARK: - Layout logic

/// Stack layout is generalized to work for both Rows and Columns.
///
/// Some special terminology is used to symbolically represent the two axes of a stack:
///
///   - The axis along which elements are being laid out is generally called "axis".
///   - The other axis is the cross axis, or just "cross".
///
/// For Rows, the axis is horizontal and the cross is vertical.
/// For Columns, the axis is vertical and the cross is horizontal.
///
///```
/// Row──────────────────────────────────┐
/// │┌───────┐                      ▲    │
/// ││       │┌───────┐         ┌───┼───┐│
/// ││       ││       │         │   │   ││
/// ││       ││       │┌───────┐│ Cross ││
/// ││       ││       ││       ││   │   ││
/// │◀───────┼┼─────Axis───────┼┼───┼───▶│
/// ││       ││       ││       ││   │   ││
/// ││       ││       │└───────┘│   │   ││
/// ││       ││       │         │   │   ││
/// ││       │└───────┘         └───┼───┘│
/// │└───────┘                      ▼    │
/// └────────────────────────────────────┘
///
///      Column────────────────────┐
///      │┌───────────▲───────────┐│
///      ││           │           ││
///      ││         Axis          ││
///      ││           │           ││
///      │└───────────┼───────────┘│
///      │   ┌────────┼────────┐   │
///      │   │        │        │   │
///      │◀──┼────────┼─Cross──┼──▶│
///      │   │        │        │   │
///      │   └────────┼────────┘   │
///      │       ┌────┼────┐       │
///      │       │    │    │       │
///      │       │    │    │       │
///      │       │    │    │       │
///      │       └────┼────┘       │
///      │   ┌────────┼────────┐   │
///      │   │        │        │   │
///      │   │        │        │   │
///      │   │        │        │   │
///      │   └────────▼────────┘   │
///      └─────────────────────────┘
/// ```
///
extension StackLayout {

    private func _layout(size: CGSize, items: [LayoutItem<Self>]) -> [LayoutAttributes] {
        guard items.count > 0 else { return [] }

        // During layout the constraints are always `.exactly` to fit the provided size
        let vectorConstraint = size.vectorConstraint(axis: axis)

        let frames = _frames(for: items, in: vectorConstraint)
        
        return frames.map { frame in
            return LayoutAttributes(frame: frame.rect(axis: axis))
        }
    }

    private func _measureIn(constraint: SizeConstraint, items: [LayoutItem<Self>]) -> CGSize {
        guard items.count > 0 else { return .zero }

        // During measurement the constraints may be `.atMost` or `.unconstrained` to fit the measurement constraint
        let vectorConstraint = constraint.vectorConstraint(on: axis)

        let frames = _frames(for: items, in: vectorConstraint)

        let vector = frames.reduce(Vector.zero) { (vector, frame) -> Vector in
            Vector(
                axis: max(vector.axis, frame.maxAxis),
                cross: max(vector.cross, frame.maxCross)
            )
        }

        return vector.size(axis: axis)
    }

    private func _frames(
        for items: [LayoutItem<Self>],
        in vectorConstraint: VectorConstraint
    ) -> [VectorFrame] {
        // First allocate available space along the layout axis.
        let axisSegments = _axisSegments(for: items, in: vectorConstraint)

        // Then measure cross axis for each item based on the space it was allocated.
        let crossSegments = _crossSegments(
            for: items,
            axisConstraints: axisSegments.map { $0.magnitude },
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
    ///```
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
    ///```
    ///
    /// - Parameters:
    ///   - for: The items to measure.
    ///   - in: The contraint for all measurements.
    /// - Returns: The axis measurements as segments.
    private func _axisSegments(
        for items: [LayoutItem<Self>],
        in vectorConstraint: VectorConstraint
    ) -> [Segment] {
        let constraint = vectorConstraint.constraint(axis: axis)

        /// The measured sizes of each item, constrained as if each were the only element in the stack.
        let basisSizes = items.map { $0.content.size(in: constraint).axis(on: axis) }

        func unconstrainedAxisSize() -> CGFloat {
            let totalMeasuredAxis: CGFloat = basisSizes.reduce(0.0, +)
            let minimumTotalSpacing = CGFloat(items.count-1) * minimumSpacing

            return totalMeasuredAxis + minimumTotalSpacing
        }

        switch vectorConstraint.axis {
        case .exactly(let axisSize):
            if unconstrainedAxisSize() >= axisSize {
                // Overflow: compress to axis constraint
                return _layoutOverflow(
                    basisSizes: basisSizes,
                    traits: items.map { $0.traits },
                    layoutSize: axisSize)
            } else {
                // Underflow: expand to axis constraint
                return _layoutUnderflow(
                    basisSizes: basisSizes,
                    traits: items.map { $0.traits },
                    layoutSize: axisSize)
            }

        case .atMost(let axisMax):
            if unconstrainedAxisSize() >= axisMax {
                // Overflow: compress to axis constraint
                return _layoutOverflow(
                    basisSizes: basisSizes,
                    traits: items.map { $0.traits },
                    layoutSize: axisMax)
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
        let totalSpacing = minimumSpacing * CGFloat(basisSizes.count-1)

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

        let axisSegments = zip(basisSizes, shrinkPriorities).map { (basis, shrinkPriority) -> Segment in
            let sizeAdjustment = (shrinkPriority / totalPriority) * extraSize
            let magnitude = basis + sizeAdjustment
            let origin = axisOrigin

            axisOrigin = origin + magnitude + minimumSpacing

            return Segment(origin: origin, magnitude: magnitude)
        }

        return axisSegments
    }

    private func _layoutUnderflow(basisSizes: [CGFloat], traits: [Traits], layoutSize: CGFloat) -> [Segment] {
        assert(basisSizes.count > 0)

        let totalBasisSize: CGFloat = basisSizes.reduce(0.0, +)

        let minimumTotalSpace = minimumSpacing * CGFloat(basisSizes.count-1)
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
            space = (layoutSize - totalBasisSize) / CGFloat(basisSizes.count-1)
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
            axisOrigin = (extraSize / 2.0).rounded() // TODO: @narenh - Add screen scale rounding
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

        let axisSegments = zip(basisSizes, growPriorities).map { (basis, growPriority) -> Segment in
            let sizeAdjustment = (growPriority / totalPriority) * extraSize
            let origin = axisOrigin
            let magnitude = basis + sizeAdjustment

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
    ///```
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
    ///```
    ///
    /// - Parameters:
    ///   - for: The items to measure.
    ///   - axisConstraints: The axis components of the constraint for each measurement.
    ///   - crossConstraint: The cross component of the constraint for all measurements.
    /// - Returns: The cross measurements as segments.
    private func _crossSegments(
        for items: [LayoutItem<Self>],
        axisConstraints: [CGFloat],
        crossConstraint: VectorConstraint.Axis
    ) -> [Segment] {
        // First, measure cross magnitudes based on axis constraints
        let crossMagnitudes = zip(items, axisConstraints).map { (item, axisConstraint) -> CGFloat in
            let vector = VectorConstraint(
                axis: .atMost(axisConstraint),
                cross: crossConstraint)
            let constraint = vector.constraint(axis: axis)
            let measuredSize = item.content.size(in: constraint)

            return measuredSize.cross(on: axis)
        }

        // Then pick the max cross value based on the constraint
        let maxCross: CGFloat
        switch crossConstraint {
        case .unconstrained:
            maxCross = crossMagnitudes.reduce(0, max)
        case .exactly(let exactConstraint):
            maxCross = exactConstraint
        case .atMost(let maxConstraint):
            let maxMagnitude = crossMagnitudes.reduce(0, max)
            maxCross = min(maxConstraint, maxMagnitude)
        }

        // Finally, form segments from the magnitudes and the alignment option
        let segments = zip(items, crossMagnitudes).map { (item, measuredCross) -> Segment in
            let origin: CGFloat
            let magnitude: CGFloat

            switch alignment {
            case .center:
                origin = (maxCross - measuredCross) / 2.0
                magnitude = measuredCross

            case .fill:
                origin = 0.0
                magnitude = maxCross

            case .leading:
                origin = 0.0
                magnitude = measuredCross

            case .trailing:
                origin = maxCross - measuredCross
                magnitude = measuredCross
            }

            return Segment(origin: origin, magnitude: magnitude)
        }

        return segments
    }

    // MARK: - Layout types

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
                return CGSize(width: self.axis, height: self.cross)
            case .vertical:
                return CGSize(width: self.cross, height: self.axis)
            }
        }

        func point(axis: StackLayout.Axis) -> CGPoint {
            switch axis {
            case .horizontal:
                return CGPoint(x: self.axis, y: self.cross)
            case .vertical:
                return CGPoint(x: self.cross, y: self.axis)
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

        init(origin: Vector, size: Vector) {
            self.origin = origin
            self.size = size
        }

        init(axis: Segment, cross: Segment) {
            self.origin = Vector(axis: axis.origin, cross: cross.origin)
            self.size = Vector(axis: axis.magnitude, cross: cross.magnitude)
        }

        func rect(axis: StackLayout.Axis) -> CGRect {
            return CGRect(origin: origin.point(axis: axis), size: size.size(axis: axis))
        }

        var maxAxis: CGFloat {
            return origin.axis + size.axis
        }

        var minAxis: CGFloat {
            return origin.axis
        }

        var maxCross: CGFloat {
            return origin.cross + size.cross
        }

        var minCross: CGFloat {
            return origin.cross
        }
    }
}

// MARK: - Extensions

private extension CGSize {

    func stackVector(axis: StackLayout.Axis) -> StackLayout.Vector {
        switch axis {
        case .horizontal:
            return StackLayout.Vector(axis: width, cross: height)
        case .vertical:
            return StackLayout.Vector(axis: height, cross: width)
        }
    }

    func vectorConstraint(axis: StackLayout.Axis) -> StackLayout.VectorConstraint {
        switch axis {
        case .horizontal:
            return StackLayout.VectorConstraint(
                axis: .exactly(width),
                cross: .exactly(height))
        case .vertical:
            return StackLayout.VectorConstraint(
                axis: .exactly(height),
                cross: .exactly(width))
        }
    }

    func axis(on axis: StackLayout.Axis) -> CGFloat {
        switch axis {
        case .horizontal:
            return width
        case .vertical:
            return height
        }
    }

    func cross(on axis: StackLayout.Axis) -> CGFloat {
        switch axis {
        case .horizontal:
            return height
        case .vertical:
            return width
        }
    }
}

private extension SizeConstraint {
    func vectorConstraint(on axis: StackLayout.Axis) -> StackLayout.VectorConstraint {
        switch axis {
        case .horizontal:
            return StackLayout.VectorConstraint(axis: width.vectorConstraint, cross: height.vectorConstraint)
        case .vertical:
            return StackLayout.VectorConstraint(axis: height.vectorConstraint, cross: width.vectorConstraint)
        }
    }

    func axis(on axis: StackLayout.Axis) -> SizeConstraint.Axis {
        switch axis {
        case .horizontal:
            return width
        case .vertical:
            return height
        }
    }

    func cross(on axis: StackLayout.Axis) -> SizeConstraint.Axis {
        switch axis {
        case .horizontal:
            return height
        case .vertical:
            return width
        }
    }
}

private extension SizeConstraint.Axis {
    var vectorConstraint: StackLayout.VectorConstraint.Axis {
        switch self {
        case .atMost(let max):
            return .atMost(max)
        case .unconstrained:
            return .unconstrained
        }
    }
}
