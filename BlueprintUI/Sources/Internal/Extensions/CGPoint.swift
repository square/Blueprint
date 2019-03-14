import QuartzCore
import simd

extension CGPoint {
    
    init(_ vector: double4) {
        self.init(
            x: CGFloat(vector.x),
            y: CGFloat(vector.y))
    }
    
    var double4Value: double4 {
        return double4(Double(x), Double(y), 0.0, 1.0)
    }
    
    mutating func apply(transform: CATransform3D) {
        self = applying(transform)
    }
    
    func applying(_ transform: CATransform3D) -> CGPoint {
        return CGPoint(double4Value * transform.double4x4Value)
    }
    
}
