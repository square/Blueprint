import QuartzCore
import simd

extension CATransform3D {

    init(_ double4x4Value: double4x4) {
        self.init()
        m11 = CGFloat(double4x4Value[0][0])
        m12 = CGFloat(double4x4Value[1][0])
        m13 = CGFloat(double4x4Value[2][0])
        m14 = CGFloat(double4x4Value[3][0])
        m21 = CGFloat(double4x4Value[0][1])
        m22 = CGFloat(double4x4Value[1][1])
        m23 = CGFloat(double4x4Value[2][1])
        m24 = CGFloat(double4x4Value[3][1])
        m31 = CGFloat(double4x4Value[0][2])
        m32 = CGFloat(double4x4Value[1][2])
        m33 = CGFloat(double4x4Value[2][2])
        m34 = CGFloat(double4x4Value[3][2])
        m41 = CGFloat(double4x4Value[0][3])
        m42 = CGFloat(double4x4Value[1][3])
        m43 = CGFloat(double4x4Value[2][3])
        m44 = CGFloat(double4x4Value[3][3])
    }

    var double4x4Value: double4x4 {
        double4x4(rows: [
            SIMD4(Double(m11), Double(m12), Double(m13), Double(m14)),
            SIMD4(Double(m21), Double(m22), Double(m23), Double(m24)),
            SIMD4(Double(m31), Double(m32), Double(m33), Double(m34)),
            SIMD4(Double(m41), Double(m42), Double(m43), Double(m44)),
        ])
    }

    var untranslated: CATransform3D {
        var result = self
        result.m41 = 0.0
        result.m42 = 0.0
        result.m43 = 0.0
        return result
    }

}
