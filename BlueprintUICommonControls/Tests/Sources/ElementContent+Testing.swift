import BlueprintUI
import CoreGraphics

extension ElementContent {
    /// A convenience method to measure the required size of this element's content,
    /// using a default environment.
    /// - Parameters:
    ///   - constraint: The size constraint.
    /// - returns: The layout size needed by this content.
    func measure(in constraint: SizeConstraint) -> CGSize {
        return measure(in: constraint, environment: .empty)
    }
}
