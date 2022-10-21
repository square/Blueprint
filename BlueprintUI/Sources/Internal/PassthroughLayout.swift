import CoreGraphics

// Used for elements with a single child that requires no custom layout
struct PassthroughLayout: SingleChildLayout {

    func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {
        child.measure(in: constraint)
    }

    func layout(size: CGSize, child: Measurable) -> LayoutAttributes {
        LayoutAttributes(size: size)
    }

    func sizeThatFits(proposal: ProposedViewSize, subview: LayoutSubview) -> CGSize {
        subview.sizeThatFits(proposal)
    }

    func placeSubview(in bounds: CGRect, proposal: ProposedViewSize, subview: LayoutSubview) {
        subview.place(at: bounds.origin, size: bounds.size)
    }
}
