import CoreGraphics

extension CGRect {
    /// A point composed of `midX` and `midY`.
    public var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
