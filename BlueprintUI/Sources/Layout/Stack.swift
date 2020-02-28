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


/// A layout implementation that linearly lays out an array of children along either the horizontal or vertical axis.
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

    public func measure(in constraint: SizeConstraint, items: [(traits: Traits, content: Measurable)]) -> CGSize {
        let layout = self.layout(size: constraint.maximum, items: items)
        
        let rect = layout.reduce(CGRect.zero) {
            $0.union($1.frame)
        }
        
        return rect.size
    }

    public func layout(size: CGSize, items: [(traits: Traits, content: Measurable)]) -> [LayoutAttributes] {
        
        ///
        /// **NOTE**: All layout code below is written as if we're laying out a `Column` (aka top to bottom)
        /// to make reasoning about width, height, etc, easier. We flip dimensions when laying out
        /// horizontally, via the `self.axis.width(for: ...)` or `self.axis.value(...` methods.
        ///
        
        guard items.isEmpty == false else {
            return []
        }
        
        /// !!! TODO: Deal with minimum spacing??
        
        /// Turn items into a usable type for layout.
        
        let order = LayoutOrder(all: items.mapWithIndex {
            LayoutItem(traits: $1.traits, content: $1.content, index: $0)
        })
        
        /// First, size the non-flexible items. These can't change, so we can guarantee their size in the axis direction.
        
        order.fixed.forEach {
            $0.unadjustedSize = $0.content.measure(in: SizeConstraint(size))
            $0.finalSize = $0.unadjustedSize
        }
        
        /// Figure out the remaining size that can be used for underflow or overflow elements.
        
        let remainingHeight = self.axis.height(for: size) - order.fixed.reduce(.zero) {
            $0 + self.axis.height(for: $1.finalSize)
        }
        
        /// !!! TODO: Guard here and below that remainingWidth is more than zero. Otherwise we should bail; measuring in 0 is meaningless.
        
        /// Now, size all of the flexible elements based on the remaining width. We'll adjust the size
        /// to account for grow and shrink later on.
        
        order.flexible.forEach {
            $0.unadjustedSize = $0.content.measure(in: SizeConstraint(self.axis.value(
                ifHorizontal: CGSize(width: remainingHeight, height: size.height),
                ifVertical: CGSize(width: size.width, height: remainingHeight)
            )))
        }
        
        /// Assign the unadjusted size multipliers, which we'll later use to resize the elements.
        
        let totalFlexibleItemsHeight : CGFloat = order.flexible.reduce(.zero) {
            $0 + self.axis.height(for: $1.unadjustedSize)
        }
        
        /// How much larger is the `totalFlexibleWidth` vs. the actual `remainingWidth`?
        
        let flexibleHeightMultiplier = remainingHeight / totalFlexibleItemsHeight
        
        /// !!! TODO: Actually scale by the actual shrink and grow amount. But for now, assume they're always either 1 or 0.
        
        /// Now, re-size flexible elements based on the flex multiplier, if it's not 1.0.
        
        if flexibleHeightMultiplier != 1.0 { // Eventually split this into an if/else around >1 <1, but for now...
            
            order.flexible.forEach {
                let adjustedHeight = self.axis.height(for: $0.unadjustedSize) * flexibleHeightMultiplier
                
                let constraint = SizeConstraint(self.axis.value(
                    ifHorizontal: CGSize(width: adjustedHeight, height: size.height),
                    ifVertical: CGSize(width: size.width, height: adjustedHeight)
                ))
                
                $0.finalSize = $0.content.measure(in: constraint)
            }
        }
        
        /// Lay out each item vertically.
        
        var lastY : CGFloat = 0.0
        
        order.all.forEachWithIndex {
            let isLast = ($0 == order.all.count - 1)
            
            $1.origin = self.axis.value(
                ifHorizontal: CGPoint(x: lastY, y: 0.0),
                ifVertical: CGPoint(x: 0.0, y: lastY)
            )
            
            lastY += self.axis.height(for: $1.finalSize)
            
            if isLast == false {
                lastY += self.minimumSpacing
            }
        }
        
        /// Done! Wow!! (Map values back into layout attributes)
        
        return order.all.map {
            LayoutAttributes(frame: CGRect(origin: $0.origin, size: $0.finalSize))
        }
    }
}


extension StackLayout {
    
    final class LayoutItem {
        var traits : Traits
        var content : Measurable
        
        var index : Int
        
        var origin : CGPoint = .zero
        
        var unadjustedSize : CGSize = .zero
        var unadjustedSizeMultiplier : Double = .zero
        
        var finalSize : CGSize = .zero
        
        init(
            traits : Traits,
            content : Measurable,
            index : Int
        ) {
            self.traits = traits
            self.content = content
            
            self.index = index
        }
    }
    
    final class LayoutOrder {
        
        var all : [LayoutItem]
        
        var fixed : [LayoutItem]
        var flexible : [LayoutItem]
        
        init(all: [LayoutItem])
        {
            self.all = all
            
            self.fixed = all.filter { $0.traits.growPriority == 0.0 && $0.traits.shrinkPriority == 0.0 }
            self.flexible = all.filter { $0.traits.growPriority != 0.0 || $0.traits.shrinkPriority != 0.0 }
        }
    }
}

extension StackLayout {

    /// The direction of the stack.
    public enum Axis : Equatable {
        
        /// Used for the `Row` type.
        case horizontal
        
        /// Used for the `Column` type.
        case vertical
        
        func value<Value>(ifHorizontal : @autoclosure () -> Value, ifVertical : @autoclosure () -> Value) -> Value
        {
            switch self {
            case .horizontal: return ifHorizontal()
            case .vertical: return ifVertical()
            }
        }
        
        func value<Value>(ifHorizontal : () -> Value, ifVertical : () -> Value) -> Value
        {
            switch self {
            case .horizontal: return ifHorizontal()
            case .vertical: return ifVertical()
            }
        }
        
        func width(for size : CGSize) -> CGFloat {
            switch self {
            case .horizontal: return size.height
            case .vertical: return size.width
            }
        }
        
        func height(for size : CGSize) -> CGFloat {
            switch self {
            case .horizontal: return size.width
            case .vertical: return size.height
            }
        }
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


extension Array {
    
    func mapWithIndex<Mapped>(_ map : (Int, Element) -> Mapped) -> [Mapped]
    {
        var mapped = [Mapped]()
        
        for (index, value) in self.enumerated() {
            mapped.append(map(index, value))
        }
        
        return mapped
    }
    
    func forEachWithIndex(_ body : (Int, Element) -> ())
    {
        for (index, element) in self.enumerated() {
            body(index, element)
        }
    }
}
