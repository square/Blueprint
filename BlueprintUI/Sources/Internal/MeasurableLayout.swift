import CoreGraphics

// Used for empty elements with an intrinsic size
// struct MeasurableLayout: Layout {
//
//    var measurable: Measurable
//
//    func measure(in constraint: SizeConstraint, items: [(traits: (), content: Measurable)]) -> CGSize {
//        precondition(items.isEmpty)
//        return measurable.measure(in: constraint)
//    }
//
//    func layout(size: CGSize, items: [(traits: (), content: Measurable)]) -> [LayoutAttributes] {
//        precondition(items.isEmpty)
//        return []
//    }
//
//    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews) -> CGSize {
//        .zero
//    }
//
//    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews) {
//
//    }
// }
