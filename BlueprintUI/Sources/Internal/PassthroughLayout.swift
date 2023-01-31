import CoreGraphics

// Used for elements with a single child that requires no custom layout
struct PassthroughLayout: SingleChildLayout {

    func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {
        child.measure(in: constraint)
    }

    func layout(size: CGSize, child: Measurable) -> LayoutAttributes {
        LayoutAttributes(size: size)
    }

    func sizeThatFits(proposal: SizeConstraint, subview: LayoutSubview, cache: inout Cache) -> CGSize {
        subview.sizeThatFits(proposal)
    }

    func placeSubview(in bounds: CGRect, proposal: SizeConstraint, subview: LayoutSubview, cache: inout ()) {
        subview.place(at: bounds)
    }
    
    func layout(in context: StrictLayoutContext, child: StrictLayoutable) -> StrictLayoutAttributes {
        StrictLayoutAttributes(
            size: child.layout(in: context.proposedSize),
            childPositions: [.zero]
        )
    }
}
