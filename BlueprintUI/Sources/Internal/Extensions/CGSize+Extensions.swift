import UIKit

extension CGSize {
    static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }

    static func - (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }

    func inset(by insets: UIEdgeInsets) -> Self {
        CGSize(
            width: width - insets.left - insets.right,
            height: height - insets.top - insets.bottom
        )
    }

    func upperBounded(by maxSize: CGSize) -> CGSize {
        CGSize(width: min(width, maxSize.width), height: min(height, maxSize.height))
    }
}
