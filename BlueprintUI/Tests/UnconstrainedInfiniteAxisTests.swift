import BlueprintUI
import XCTest

class UnconstrainedInfiniteAxisTests: XCTestCase {
    struct ConstrainedAxis {
        @SizeConstraint.UnconstrainedInfiniteAxis var axis: SizeConstraint.Axis
    }

    func test_initialValue() {
        do {
            let axis = ConstrainedAxis(axis: .atMost(.infinity))
            XCTAssertEqual(axis.axis, .unconstrained)
        }

        do {
            let axis = ConstrainedAxis(axis: .atMost(.greatestFiniteMagnitude))
            XCTAssertEqual(axis.axis, .unconstrained)
        }

        do {
            let axis = ConstrainedAxis(axis: .atMost(100))
            XCTAssertEqual(axis.axis, .atMost(100))
        }

        do {
            let axis = ConstrainedAxis(axis: .unconstrained)
            XCTAssertEqual(axis.axis, .unconstrained)
        }
    }

    func test_settingValue() {
        do {
            var axis = ConstrainedAxis(axis: .atMost(100))
            axis.axis = .atMost(.infinity)
            XCTAssertEqual(axis.axis, .unconstrained)
        }

        do {
            var axis = ConstrainedAxis(axis: .atMost(100))
            axis.axis = .atMost(.greatestFiniteMagnitude)
            XCTAssertEqual(axis.axis, .unconstrained)
        }

        do {
            var axis = ConstrainedAxis(axis: .atMost(100))
            axis.axis = .atMost(200)
            XCTAssertEqual(axis.axis, .atMost(200))
        }

        do {
            var axis = ConstrainedAxis(axis: .atMost(100))
            axis.axis = .unconstrained
            XCTAssertEqual(axis.axis, .unconstrained)
        }
    }
}
