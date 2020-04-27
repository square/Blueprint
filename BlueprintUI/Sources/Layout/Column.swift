import UIKit

/// Displays a list of items in a linear vertical layout.
public struct Column: StackElement {

    public var children: [StackChild] = []
    
    public var defaults: StackDefaults

    private (set) public var layout : StackLayout
    
    public init(
        alignment : StackLayout.Alignment = .leading,
        underflow : StackLayout.UnderflowDistribution = .growUniformly,
        overflow : StackLayout.OverflowDistribution = .condenseUniformly,
        @ColumnBuilder build: () -> ColumnBuilder.Content
    ) {
        self.init(
            alignment: alignment,
            underflow: underflow,
            overflow: overflow
        )
        
        let content = build()

        switch content {
        case .empty: break
        case .single(let child): self.children = [child]
        case .multiple(let children): self.children = children
        }
    }

    public init(
        alignment : StackLayout.Alignment = .leading,
        underflow : StackLayout.UnderflowDistribution = .growUniformly,
        overflow : StackLayout.OverflowDistribution = .condenseUniformly,
        configure: (inout Column) -> () = { _ in }
    ) {
        self.defaults = StackDefaults()
        
        self.layout = StackLayout(axis: .horizontal) {
            $0.alignment = alignment
            $0.underflow = underflow
            $0.overflow = overflow
        }
        
        configure(&self)
    }

    public var verticalUnderflow: StackLayout.UnderflowDistribution {
        get { return layout.underflow }
        set { layout.underflow = newValue }
    }

    public var verticalOverflow: StackLayout.OverflowDistribution {
        get { return layout.overflow }
        set { layout.overflow = newValue }
    }

    public var horizontalAlignment: StackLayout.Alignment {
        get { return layout.alignment }
        set { layout.alignment = newValue }
    }

    public var minimumVerticalSpacing: CGFloat {
        get { return layout.minimumSpacing }
        set { layout.minimumSpacing = newValue }
    }
}

// Experimental

@_functionBuilder
public struct ColumnBuilder {
    public static func buildBlock(_ children : StackChild...) -> Content {
        .multiple(Array(children))
    }
    
    public static func buildBlock() -> Content {
        .empty
    }
    
    public static func buildBlock(_ elements : Element...) -> Content {
        .multiple(elements.map { element in
            StackChild(traits: .init(growPriority: 0.0, shrinkPriority: 0.0), key: nil, element: element )
        })
    }
    
    public enum Content {
        case empty
        case single(StackChild)
        case multiple([StackChild])
    }
}
