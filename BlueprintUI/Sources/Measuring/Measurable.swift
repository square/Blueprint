import UIKit

/// Conforming types can calculate the size that they require within a layout.
public protocol Measurable {

    /// Measures the required size of the receiver.
    ///
    /// - parameter context: The context describing the layout environment.
    ///
    /// - returns: The layout size needed by the receiver.
    func measure(
        in constraint : SizeConstraint,
        with context: LayoutContext
    ) -> CGSize
}

