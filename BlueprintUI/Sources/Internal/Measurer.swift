import CoreGraphics

struct Measurer: Measurable {
    var _measure: (SizeConstraint) -> CGSize
    func measure(in constraint: SizeConstraint) -> CGSize {
        _measure(constraint)
    }
}
