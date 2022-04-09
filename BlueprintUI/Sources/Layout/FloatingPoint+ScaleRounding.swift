import Foundation

extension FloatingPoint {
    /// Rounds this value to the specified scale, where the scale is the number of rounding stops per integer.
    /// - Parameters:
    ///   - rule: the rounding rule
    ///   - scale: the rounding scale
    ///
    /// A rounding scale of 1.0 is standard integer rounding.
    /// A rounding scale of 2.0 rounds to halves (0, 0.5, 1.0, 1.5, 2.0, 2.5., ...).
    /// A rounding scale of 3.0 rounds to thirds (0, 1/3, 2/3, 1.0, 4/3, 5/3, 2.0, ...).
    public mutating func round(_ rule: FloatingPointRoundingRule, by scale: Self) {
        self = rounded(rule, by: scale)
    }

    /// Returns this value rounded to the specified scale, where the scale is the number of rounding stops per integer.
    /// - Parameters:
    ///   - rule: the rounding rule
    ///   - scale: the rounding scale
    /// - Returns: The rounded value.
    ///
    /// A rounding scale of 1.0 is standard integer rounding.
    /// A rounding scale of 2.0 rounds to halves (0, 0.5, 1.0, 1.5, 2.0, 2.5., ...).
    /// A rounding scale of 3.0 rounds to thirds (0, 1/3, 2/3, 1.0, 4/3, 5/3, 2.0, ...).
    public func rounded(_ rule: FloatingPointRoundingRule, by scale: Self) -> Self {
        (self * scale).rounded(rule) / scale
    }
}
