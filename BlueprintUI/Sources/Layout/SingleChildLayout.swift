import UIKit

/// Conforming types can calculate layout attributes for an array of children.
public protocol SingleChildLayout: SPSingleChildLayout {

    /// Computes the size that this layout requires
    ///
    /// - parameter constraint: The size constraint in which measuring should occur.
    /// - parameter child: A `Measurable` representing the single child of this layout.
    ///
    /// - returns: The measured size.
    func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize

    /// Generates layout attributes for the child.
    ///
    /// - parameter size: The size that layout attributes should be generated within.
    ///
    /// - parameter child: A `Measurable` representing the single child of this layout.
    ///
    /// - returns: Layout attributes for the child of this layout.
    func layout(size: CGSize, child: Measurable) -> LayoutAttributes

}

public protocol SPSingleChildLayout {
    
    func sizeThatFits(proposal: ProposedViewSize, subview: LayoutSubview) -> CGSize
    
    func placeSubview(in bounds: CGRect, proposal: ProposedViewSize, subview: LayoutSubview)
}

extension SingleChildLayout {
    public func sizeThatFits(proposal: ProposedViewSize, subview: LayoutSubview) -> CGSize {
        fatalError()
    }
    
    public func placeSubview(in bounds: CGRect, proposal: ProposedViewSize, subview: LayoutSubview) {
        fatalError()
    }
}

