import QuartzCore
import simd

extension CGPoint {

    init(_ vector: SIMD4<Double>) {
        self.init(
            x: CGFloat(vector.x),
            y: CGFloat(vector.y)
        )
    }

    var double4Value: SIMD4<Double> {
        SIMD4(Double(x), Double(y), 0.0, 1.0)
    }

    mutating func apply(transform: CATransform3D) {
        self = applying(transform)
    }

    func applying(_ transform: CATransform3D) -> CGPoint {
        CGPoint(double4Value * transform.double4x4Value)
    }

    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    static prefix func - (point: CGPoint) -> CGPoint {
        CGPoint(x: -point.x, y: -point.y)
    }
}
