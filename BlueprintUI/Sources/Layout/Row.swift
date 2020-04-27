import UIKit

/// Displays a list of items in a linear horizontal layout.
public struct Row: StackElement {

    public var children: [StackChild] = []
    
    public var defaults: StackDefaults

    private (set) public var layout : StackLayout

    public init(
        alignment : StackLayout.Alignment = .leading,
        underflow : StackLayout.UnderflowDistribution = .growUniformly,
        overflow : StackLayout.OverflowDistribution = .condenseUniformly,
        _ configure: (inout Self) -> Void
    ) {
        self.defaults = StackDefaults()
        
        self.layout = StackLayout(axis: .horizontal) {
            $0.alignment = alignment
            $0.underflow = underflow
            $0.overflow = overflow
        }
        
        configure(&self)
    }

    public var horizontalUnderflow: StackLayout.UnderflowDistribution {
        get { return layout.underflow }
        set { layout.underflow = newValue }
    }

    public var horizontalOverflow: StackLayout.OverflowDistribution {
        get { return layout.overflow }
        set { layout.overflow = newValue }
    }

    public var verticalAlignment: StackLayout.Alignment {
        get { return layout.alignment }
        set { layout.alignment = newValue }
    }

    public var minimumHorizontalSpacing: CGFloat {
        get { return layout.minimumSpacing }
        set { layout.minimumSpacing = newValue }
    }
}
