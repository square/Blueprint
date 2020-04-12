import UIKit

public struct GridLayout: Layout {
    
    public init() {}
    
    public enum Direction: Equatable {
        case horizontal(rows: Int)
        case vertical(columns: Int)
        
        fileprivate var primaryDimensionSize: Int {
            switch self {
            case .horizontal(let rows):
                return rows
            case .vertical(let cols):
                return cols
            }
        }
    }
    
    public var direction: Direction = .vertical(columns: 4)
    
    public var gutter: CGFloat = 10.0
    
    public var margin: CGFloat = 0.0
    
    public func layout(in constraint : SizeConstraint, items: [LayoutItem<Self>]) -> LayoutResult {
        LayoutResult(
            size: {
                let primarySize = direction.primaryDimensionSize
                let secondarySize = Int(ceil(Double(items.count) / Double(primarySize)))
                
                let itemSize: CGFloat
                switch direction {
                case .horizontal(let rows):
                    itemSize = (constraint.maximum.height - (margin * 2.0) - (CGFloat(rows - 1) * gutter)) / CGFloat(rows)
                    return CGSize(
                        width: margin*2.0 + gutter*CGFloat(secondarySize-1) + itemSize*CGFloat(secondarySize),
                        height: constraint.maximum.height
                    )
                case .vertical(let cols):
                    itemSize = (constraint.maximum.width - (margin * 2.0) - (CGFloat(cols - 1) * gutter)) / CGFloat(cols)
                    return CGSize(
                        width: constraint.maximum.width,
                        height: margin*2.0 + gutter*CGFloat(secondarySize-1) + itemSize*CGFloat(secondarySize)
                    )
                }
            },
            layoutAttributes: { size in
                guard items.count > 0 else { return [] }
                
                precondition(direction.primaryDimensionSize > 0)
                
                let itemSize: CGFloat
                switch direction {
                case .horizontal(let rows):
                    itemSize = (size.height - (margin * 2.0) - (CGFloat(rows - 1) * gutter)) / CGFloat(rows)
                case .vertical(let cols):
                    itemSize = (size.width - (margin * 2.0) - (CGFloat(cols - 1) * gutter)) / CGFloat(cols)
                }
                
                let primarySize = direction.primaryDimensionSize
                
                var result: [LayoutAttributes] = []
                
                for (index, _) in items.enumerated() {
                    let primaryPosition = index % primarySize
                    let secondaryPosition = index / primarySize
                    
                    var frame = CGRect.zero
                    frame.size.width = itemSize
                    frame.size.height = itemSize
                    
                    switch direction {
                    case .horizontal(_):
                        frame.origin.x = margin + (itemSize + gutter) * CGFloat(secondaryPosition)
                        frame.origin.y = margin + (itemSize + gutter) * CGFloat(primaryPosition)
                    case .vertical(_):
                        frame.origin.x = margin + (itemSize + gutter) * CGFloat(primaryPosition)
                        frame.origin.y = margin + (itemSize + gutter) * CGFloat(secondaryPosition)
                    }
                    
                    result.append(LayoutAttributes(frame: frame))
                }
                
                return result
            }
        )
    }
}
