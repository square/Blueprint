import Foundation

/// Represents a scale rounding behavior for `CGFloat`s.
public enum RoundingScale: Equatable {
    /// Do not round
    case none

    /// Round to the specified scale, where the scale is the number of rounding stops per integer.
    ///
    /// Examples
    /// ========
    /// A rounding scale of 1.0 is standard integer rounding.
    /// A rounding scale of 2.0 rounds to halves (0, 0.5, 1.0, 1.5, 2.0, 2.5., ...).
    /// A rounding scale of 3.0 rounds to thirds (0, 1/3, 2/3, 1.0, 4/3, 5/3, 2.0, ...).
    case scale(_: CGFloat)

    /// Round the specified value according to the given rounding rule.
    ///
    /// - Parameters:
    ///   - value: the value to round
    ///   - rule: the rounding rule
    /// - Returns: the rounded value
    public func round(_ value: CGFloat, _ rule: FloatingPointRoundingRule) -> CGFloat {
        switch self {
        case .none:
            return value

        case .scale(let scale):
            return (value * scale).rounded(rule) / scale
        }
    }
}
