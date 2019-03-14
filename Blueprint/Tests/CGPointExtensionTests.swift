import XCTest
@testable import Blueprint

class CGPointExtensionTests: XCTestCase {
    
    func testTransformApplication() {
        
        let point = CGPoint(x: 100.0, y: 100.0)
        
        let scaleTransform = CATransform3DMakeScale(0.5, 0.5, 0.5)
        let scaledPoint = point.applying(scaleTransform)
        XCTAssertEqual(scaledPoint, CGPoint(x: 50.0, y: 50.0))
        
        let rotateTransform = CATransform3DMakeRotation(.pi, 0.0, 0.0, 1.0)
        let rotatedPoint = point.applying(rotateTransform)
        XCTAssertEqual(rotatedPoint, CGPoint(x: -100.0, y: -100.0))
        
        let translateTransform = CATransform3DMakeTranslation(33.0, 22.0, 0.0)
        let translatedPoint = point.applying(translateTransform)
        XCTAssertEqual(translatedPoint, CGPoint(x: 133.0, y: 122.0))
    }
    
}
