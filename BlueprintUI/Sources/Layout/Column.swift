import UIKit

/// Displays a list of items in a linear vertical layout.
public struct Column: StackElement {

    public var children: [(element: Element, traits: StackLayout.Traits, key: AnyHashable?)] = []

    private (set) public var layout = StackLayout(axis: .vertical)

    public init() {}

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
