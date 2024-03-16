import CoreGraphics

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
}
