import UIKit

/// Displays a list of items in a linear horizontal layout.
public struct Row: StackElement {

    public var children: [(element: Element, traits: StackLayout.Traits, key: AnyHashable?)] = []

    private (set) public var layout = StackLayout(axis: .horizontal)

    public init() {}

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
