import Foundation

extension FloatingPoint {
    mutating func round(_ rule: FloatingPointRoundingRule, by scale: Self) {
        self = self.rounded(rule, by: scale)
    }

    func rounded(_ rule: FloatingPointRoundingRule, by scale: Self) -> Self {
        return (self * scale).rounded(rule) / scale
    }
}
