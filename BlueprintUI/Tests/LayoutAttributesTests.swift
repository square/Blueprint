import XCTest
import QuartzCore
@testable import BlueprintUI

final class LayoutAttributesTests: XCTestCase {
    
    
    
    
    func testEquality() {
        
        let attributes = LayoutAttributes(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        do {
            /// Unchanged
            let other = attributes
            XCTAssertEqual(attributes, other)
        }
        
        do {
            /// Center
            var other = attributes
            other.center = CGPoint(x: 20, y: 20)
            XCTAssertNotEqual(attributes, other)
        }
        
        do {
            /// Bounds
            var other = attributes
            other.bounds = CGRect(x: 0.0, y: 20.0, width: 40.0, height: 80.0)
            XCTAssertNotEqual(attributes, other)
        }
        
        do {
            /// Alpha
            var other = attributes
            other.alpha = 0.5
            XCTAssertNotEqual(attributes, other)
        }
        
        do {
            /// Transform
            var other = attributes
            other.transform = CATransform3DMakeScale(2.0, 3.0, 5.0)
            XCTAssertNotEqual(attributes, other)
        }
        
    }
    
    func testConcatAlpha() {
        var a = LayoutAttributes(frame: .zero)
        a.alpha = 0.5
        var b = LayoutAttributes(frame: .zero)
        b.alpha = 0.5
        let combined = b.within(a)
        XCTAssertEqual(combined.alpha, 0.25)
    }
    
    func testConcatCenter() {
        
        do {
            var a = LayoutAttributes()
            a.center = CGPoint(x: 100, y: 0)
            
            var b = LayoutAttributes()
            b.center = CGPoint(x: 25, y: 50)
            
            let combined = b.within(a)
            
            XCTAssertEqual(combined.center.x, 125)
            XCTAssertEqual(combined.center.y, 50)
        }
        
        do {
            var a = LayoutAttributes()
            a.center = .zero
            a.bounds.size = CGSize(width: 100.0, height: 100.0)
            
            var b = LayoutAttributes()
            b.center = CGPoint(x: 25, y: 10)
            
            let combined = b.within(a)
            
            XCTAssertEqual(combined.center.x, -25)
            XCTAssertEqual(combined.center.y, -40)
        }
        
        do {
            var a = LayoutAttributes()
            a.center = .zero
            a.bounds.size = CGSize(width: 200.0, height: 200.0)
            
            var b = LayoutAttributes()
            b.center = .zero
            
            let combined = b.within(a)
            
            XCTAssertEqual(combined.center.x, -100)
            XCTAssertEqual(combined.center.y, -100)
        }
        
        do {
            var a = LayoutAttributes()
            a.center = .zero
            a.bounds.size = CGSize(width: 200.0, height: 200.0)
            a.transform = CATransform3DMakeRotation(.pi, 0.0, 0.0, 1.0)
            
            var b = LayoutAttributes()
            b.center = .zero
            
            let combined = b.within(a)

            if MemoryLayout<CGFloat>.size == 4 {
                XCTAssertEqual(combined.center.x.rounded(), 100)
                XCTAssertEqual(combined.center.y.rounded(), 100)
            } else {
                XCTAssertEqual(combined.center.x, 100)
                XCTAssertEqual(combined.center.y, 100)
            }
        }

    }
    
}
