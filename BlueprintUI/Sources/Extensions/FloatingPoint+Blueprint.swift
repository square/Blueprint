import Foundation

extension FloatingPoint {
    /// Returns `replacement` if `self.isInfinite` is `true`, or `self` if `self` is finite.
    public func replacingInfinity(with replacement: Self) -> Self {
        assert(replacement.isFinite, "Infinity replacement value must be finite")

        return isInfinite ? replacement : self
    }
}
