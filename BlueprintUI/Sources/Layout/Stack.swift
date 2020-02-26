import UIKit

/// Conforming types (Row and Column) act as StackLayout powered containers.
///
/// This protocol should only be used by Row and Column elements (you should never add conformance to other custom
/// types).
public protocol StackElement: Element {
    init()
    var layout: StackLayout { get }
    var children: [(element: Element, traits: StackLayout.Traits, key: String?)] { get set }
}

extension StackElement {

    public var content: ElementContent {
        return ElementContent(layout: layout) {
            for child in self.children {
                $0.add(traits: child.traits, key: child.key, element: child.element)
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
    mutating public func add(growPriority: CGFloat = 1.0, shrinkPriority: CGFloat = 1.0, key: String? = nil, child: Element) {
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

    public func measure(in constraint: SizeConstraint, environment: Environment, items: [(traits: Traits, content: Measurable)]) -> CGSize {
        let size = _measureIn(constraint: constraint, environment: environment, items: items)
        return size
    }

    public func layout(size: CGSize, environment: Environment, items: [(traits: Traits, content: Measurable)]) -> [LayoutAttributes] {
        return _layout(size: size, environment: environment, items: items)
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

        /// Additional space will be evenly devided into the spacing between items.
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

extension StackLayout {

    fileprivate func _layout(size: CGSize, environment: Environment, items: [(traits: Traits, content: Measurable)]) -> [LayoutAttributes] {

        guard items.count > 0 else { return [] }

        let constraint = SizeConstraint(size)

        let layoutSize = size.stackVector(axis: axis)

        let basisSizes = _getBasisSizes(constraint: constraint, environment: environment, items: items.map { $0.content })

        let totalMeasuredAxis: CGFloat = basisSizes.map({ $0.axis }).reduce(0.0, +)
        let minimumTotalSpacing = CGFloat(items.count-1) * minimumSpacing

        let frames: [Frame]

        /// Determine if we are dealing with overflow or underflow
        if totalMeasuredAxis + minimumTotalSpacing >= layoutSize.axis {
            /// Overflow
            frames = _layoutOverflow(basisSizes: basisSizes, traits: items.map { $0.traits }, layoutSize: layoutSize)
        } else {
            /// Underflow
            frames = _layoutUnderflow(basisSizes: basisSizes, traits: items.map { $0.traits }, layoutSize: layoutSize)
        }

        return frames.map({ (frame) -> LayoutAttributes in
            let rect = frame.rect(axis: axis)
            return LayoutAttributes(frame: rect)
        })
    }

    fileprivate func _measureIn(constraint: SizeConstraint, environment: Environment, items: [(traits: Traits, content: Measurable)]) -> CGSize {

        guard items.count > 0 else {
            return .zero
        }

        var result = Vector.zero

        for item in items {
            let measuredSize = item.content.measure(in: constraint, environment: environment).stackVector(axis: axis)
            result.axis += measuredSize.axis
            result.cross = max(result.cross, measuredSize.cross)
        }

        result.axis += minimumSpacing * CGFloat(items.count-1)

        return result.size(axis: axis)
    }

    fileprivate func _getBasisSizes(constraint: SizeConstraint, environment: Environment, items: [Measurable]) -> [Vector] {
        return items.map { $0.measure(in: constraint, environment: environment).stackVector(axis: axis) }
    }

    fileprivate func _layoutOverflow(basisSizes: [Vector], traits: [Traits], layoutSize: Vector) -> [Frame] {
        assert(basisSizes.count > 0)

        let totalBasisSize: CGFloat = basisSizes.map({ $0.axis }).reduce(0.0, +)
        let totalSpacing = minimumSpacing * CGFloat(basisSizes.count-1)

        /// The size that will be distributed among children (can be positive or negative)
        let extraSize: CGFloat = layoutSize.axis - (totalBasisSize + totalSpacing)

        assert(extraSize <= 0.0)

        var shrinkPriorities: [CGFloat] = []

        for index in 0..<basisSizes.count {
            let basis = basisSizes[index]
            let traits = traits[index]
            var priority: CGFloat
            switch overflow {
            case .condenseProportionally:
                if totalBasisSize > 0 {
                    priority = basis.axis / totalBasisSize
                } else {
                    priority = basis.axis
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

        var frames = _calculateCross(basisSizes: basisSizes, layoutSize: layoutSize)

        var axisOrigin: CGFloat = 0.0

        for index in 0..<basisSizes.count {

            let basis = basisSizes[index]

            let sizeAdjustment = (shrinkPriorities[index] / totalPriority) * extraSize
            frames[index].size.axis = basis.axis + sizeAdjustment
            frames[index].origin.axis = axisOrigin
            axisOrigin = frames[index].maxAxis + minimumSpacing
        }

        return frames
    }

    fileprivate func _layoutUnderflow(basisSizes: [Vector], traits: [Traits], layoutSize: Vector) -> [Frame] {
        assert(basisSizes.count > 0)

        let totalBasisSize: CGFloat = basisSizes.map({ $0.axis }).reduce(0.0, +)

        let minimumTotalSpace = minimumSpacing * CGFloat(basisSizes.count-1)
        let extraSize: CGFloat = layoutSize.axis - (totalBasisSize + minimumTotalSpace)
        
        assert(extraSize >= 0.0)
        
        let space: CGFloat

        switch underflow {
        case .growProportionally:
            space = minimumSpacing
        case .growUniformly:
            space = minimumSpacing
        case .spaceEvenly:
            space = (layoutSize.axis - totalBasisSize) / CGFloat(basisSizes.count-1)
        case .justifyToStart:
            space = minimumSpacing
        case .justifyToCenter:
            space = minimumSpacing
        case .justifyToEnd:
            space = minimumSpacing
        }

        var frames = _calculateCross(basisSizes: basisSizes, layoutSize: layoutSize)

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
                    priority = basis.axis / totalBasisSize
                } else {
                    priority = basis.axis
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

        for index in 0..<basisSizes.count {

            frames[index].origin.axis = axisOrigin

            let basis = basisSizes[index]

            frames[index].size.axis = basis.axis + ((growPriorities[index] / totalPriority) * extraSize)

            axisOrigin = frames[index].maxAxis + space
        }

        return frames
    }

    fileprivate func _calculateCross(basisSizes: [Vector], layoutSize: Vector) -> [Frame] {
        return basisSizes.map { (measuredSize) -> Frame in
            var result = Frame.zero
            switch alignment {
            case .center:
                result.origin.cross = (layoutSize.cross - measuredSize.cross) / 2.0
                result.size.cross = measuredSize.cross
            case .fill:
                result.origin.cross = 0.0
                result.size.cross = layoutSize.cross
            case .leading:
                result.origin.cross = 0.0
                result.size.cross = measuredSize.cross
            case .trailing:
                result.origin.cross = layoutSize.cross - measuredSize.cross
                result.size.cross = measuredSize.cross
            }
            return result
        }
    }

    fileprivate struct Vector {
        var axis: CGFloat
        var cross: CGFloat

        static var zero: Vector {
            return Vector(axis: 0.0, cross: 0.0)
        }

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

    fileprivate struct Frame {

        var origin: Vector
        var size: Vector

        static var zero: Frame {
            return Frame(origin: .zero, size: .zero)
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
    }

}

extension CGSize {

    fileprivate func stackVector(axis: StackLayout.Axis) -> StackLayout.Vector {
        switch axis {
        case .horizontal:
            return StackLayout.Vector(axis: width, cross: height)
        case .vertical:
            return StackLayout.Vector(axis: height, cross: width)
        }
    }

}

extension CGPoint {

    fileprivate func stackVector(axis: StackLayout.Axis) -> StackLayout.Vector {
        switch axis {
        case .horizontal:
            return StackLayout.Vector(axis: x, cross: y)
        case .vertical:
            return StackLayout.Vector(axis: y, cross: x)
        }
    }

}

extension CGRect {

    fileprivate func stackFrame(axis: StackLayout.Axis) -> StackLayout.Frame {
        return StackLayout.Frame(origin: origin.stackVector(axis: axis), size: size.stackVector(axis: axis))
    }
    
}
