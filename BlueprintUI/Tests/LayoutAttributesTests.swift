import UIKit
import XCTest
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

        do {
            /// User Interaction Enabled
            var other = attributes
            other.isUserInteractionEnabled = false
            XCTAssertNotEqual(attributes, other)
        }

        do {
            /// hidden
            var other = attributes
            other.isHidden = true
            XCTAssertNotEqual(attributes, other)
        }

        do {
            /// tintAdjustmentMode
            var other = attributes
            other.tintAdjustmentMode = .normal
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

            XCTAssertEqual(combined.center.x, 100, accuracy: CGFloat(100).ulp * 2)
            XCTAssertEqual(combined.center.y, 100, accuracy: CGFloat(100).ulp * 2)
        }

    }

    func test_concat_isUserInteractionEnabled() {
        do {
            var a = LayoutAttributes()
            a.isUserInteractionEnabled = true

            var b = LayoutAttributes()
            b.isUserInteractionEnabled = false

            let combined = b.within(a)

            XCTAssertFalse(combined.isUserInteractionEnabled)
        }

        do {
            var a = LayoutAttributes()
            a.isUserInteractionEnabled = false

            var b = LayoutAttributes()
            b.isUserInteractionEnabled = true

            let combined = b.within(a)

            XCTAssertFalse(combined.isUserInteractionEnabled)
        }
    }


    func test_concat_isHidden() {
        do {
            var a = LayoutAttributes()
            a.isHidden = true

            var b = LayoutAttributes()
            b.isHidden = false

            let combined = b.within(a)

            XCTAssertTrue(combined.isHidden)
        }

        do {
            var a = LayoutAttributes()
            a.isHidden = false

            var b = LayoutAttributes()
            b.isHidden = true

            let combined = b.within(a)

            XCTAssertTrue(combined.isHidden)
        }
    }

    func test_concat_tintAdjustmentMode() {
        do {
            /// combined adopts child attribute if child is non-`.automatic`
            var a = LayoutAttributes()
            a.tintAdjustmentMode = .automatic

            var b = LayoutAttributes()
            b.tintAdjustmentMode = .normal

            let combined = b.within(a)

            XCTAssertEqual(combined.tintAdjustmentMode, .normal)
        }

        do {
            /// combined adopts child attribute if both child and parent are non-`.automatic`
            var a = LayoutAttributes()
            a.tintAdjustmentMode = .dimmed

            var b = LayoutAttributes()
            b.tintAdjustmentMode = .normal

            let combined = b.within(a)

            XCTAssertEqual(combined.tintAdjustmentMode, .normal)
        }

        do {
            /// combined inherits from parent if child is `.automatic`
            var a = LayoutAttributes()
            a.tintAdjustmentMode = .normal

            var b = LayoutAttributes()
            b.tintAdjustmentMode = .automatic

            let combined = b.within(a)

            XCTAssertEqual(combined.tintAdjustmentMode, .normal)
        }

        do {
            /// combined is `.automatic` if both parent and child attributes are `.automatic`
            var a = LayoutAttributes()
            a.tintAdjustmentMode = .automatic

            var b = LayoutAttributes()
            b.tintAdjustmentMode = .automatic

            let combined = b.within(a)

            XCTAssertEqual(combined.tintAdjustmentMode, .automatic)
        }
    }
}

final class LayoutAttributesTests_CGRect: XCTestCase {

    func test_isFinite() {
        XCTAssertTrue(CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: 100.0, height: 100.0)).isFinite)

        XCTAssertFalse(CGRect(origin: CGPoint(x: 0.0, y: CGFloat.nan), size: CGSize(width: 100.0, height: 100.0)).isFinite)
        XCTAssertFalse(CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: 100.0, height: CGFloat.nan)).isFinite)
        XCTAssertFalse(CGRect(origin: CGPoint(x: 0.0, y: CGFloat.nan), size: CGSize(width: 100.0, height: CGFloat.nan)).isFinite)
    }
}

final class LayoutAttributesTests_CGPoint: XCTestCase {

    func test_isFinite() {
        XCTAssertTrue(CGPoint(x: 10.0, y: 5.0).isFinite)

        XCTAssertFalse(CGPoint(x: CGFloat.nan, y: 5.0).isFinite)
        XCTAssertFalse(CGPoint(x: 10.0, y: CGFloat.nan).isFinite)
    }
}

final class LayoutAttributesTests_CGSize: XCTestCase {

    func test_isFinite() {
        XCTAssertTrue(CGSize(width: 10.0, height: 5.0).isFinite)

        XCTAssertFalse(CGSize(width: CGFloat.nan, height: 5.0).isFinite)
        XCTAssertFalse(CGSize(width: 10.0, height: CGFloat.nan).isFinite)
    }
}

final class LayoutAttributesTests_CATransform3D: XCTestCase {

    func test_isFinite() {
        XCTAssertTrue(CATransform3DIdentity.isFinite)

        var invalid = CATransform3DIdentity
        invalid.m11 = CGFloat.nan

        XCTAssertFalse(invalid.isFinite)
    }
}

final class LayoutAttributesTests_Apply: XCTestCase {

    func test_apply_isUserInteractionEnabled() {
        var attributes = LayoutAttributes()
        attributes.isUserInteractionEnabled = false

        let view = UIView()
        attributes.apply(to: view)
        XCTAssertFalse(view.isUserInteractionEnabled)
    }

    func test_apply_isHidden() {
        var attributes = LayoutAttributes()
        attributes.isHidden = true

        let view = UIView()
        attributes.apply(to: view)
        XCTAssertTrue(view.isHidden)
    }

    func test_apply_tintAdjustmentMode() {
        var attributes = LayoutAttributes()
        attributes.tintAdjustmentMode = .normal

        let view = UIView()
        attributes.apply(to: view)
        XCTAssertEqual(view.tintAdjustmentMode, .normal)
    }
}
