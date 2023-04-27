import UIKit

extension CGSize {
    /// A size with `infinity` in both dimensions.
    public static let infinity = CGSize(width: CGFloat.infinity, height: .infinity)

    /// Returns a size with infinite dimensions replaced by the values from the given replacement.
    public func replacingInfinity(with replacement: CGSize) -> CGSize {
        assert(replacement.isFinite, "Infinity replacement value must be finite")

        return CGSize(
            width: width.replacingInfinity(with: replacement.width),
            height: height.replacingInfinity(with: replacement.height)
        )
    }

    public static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }

    public static func - (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }

    /// Returns a size inset from this size by the given inset values.
    public func inset(by insets: UIEdgeInsets) -> Self {
        CGSize(
            width: width - insets.left - insets.right,
            height: height - insets.top - insets.bottom
        )
    }

    /// Returns a size whose width and height are upper bounded by the width and height of the given
    /// maximum size.
    public func upperBounded(by maxSize: CGSize) -> CGSize {
        CGSize(width: min(width, maxSize.width), height: min(height, maxSize.height))
    }
}
