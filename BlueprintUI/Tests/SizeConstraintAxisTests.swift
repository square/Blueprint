import BlueprintUI
import XCTest

class SizeConstraintAxisTests: XCTestCase {

    func test_add() {

        // unconstrained + float
        do {
            let axis = SizeConstraint.Axis.unconstrained

            XCTAssertEqual(axis + 10, .unconstrained)
        }

        // unconstrained += float
        do {
            var axis = SizeConstraint.Axis.unconstrained

            axis += 10

            XCTAssertEqual(axis, .unconstrained)
        }

        // atMost + float
        do {
            let axis = SizeConstraint.Axis.atMost(60)

            XCTAssertEqual(axis + 10, .atMost(70))
        }

        // atMost += float
        do {
            var axis = SizeConstraint.Axis.atMost(60)

            axis += 10

            XCTAssertEqual(axis, .atMost(70))
        }

    }

    func test_subtract() {

        // unconstrained - float
        do {
            let axis = SizeConstraint.Axis.unconstrained

            XCTAssertEqual(axis - 10, .unconstrained)
        }

        // unconstrained -= float
        do {
            var axis = SizeConstraint.Axis.unconstrained

            axis -= 10

            XCTAssertEqual(axis, .unconstrained)
        }

        // atMost - float
        do {
            let axis = SizeConstraint.Axis.atMost(60)

            XCTAssertEqual(axis - 10, .atMost(50))
        }

        // atMost -= float
        do {
            var axis = SizeConstraint.Axis.atMost(60)

            axis -= 10

            XCTAssertEqual(axis, .atMost(50))
        }

    }

    func test_multiply() {

        // unconstrained * float
        do {
            let axis = SizeConstraint.Axis.unconstrained

            XCTAssertEqual(axis * 3, .unconstrained)
        }

        // unconstrained *= float
        do {
            var axis = SizeConstraint.Axis.unconstrained

            axis *= 3

            XCTAssertEqual(axis, .unconstrained)
        }

        // atMost - float
        do {
            let axis = SizeConstraint.Axis.atMost(60)

            XCTAssertEqual(axis * 3, .atMost(180))
        }

        // atMost -= float
        do {
            var axis = SizeConstraint.Axis.atMost(60)

            axis *= 3

            XCTAssertEqual(axis, .atMost(180))
        }

    }

    func test_divide() {

        // unconstrained * float
        do {
            let axis = SizeConstraint.Axis.unconstrained

            XCTAssertEqual(axis / 3, .unconstrained)
        }

        // unconstrained *= float
        do {
            var axis = SizeConstraint.Axis.unconstrained

            axis /= 3

            XCTAssertEqual(axis, .unconstrained)
        }

        // atMost - float
        do {
            let axis = SizeConstraint.Axis.atMost(60)

            XCTAssertEqual(axis / 3, .atMost(20))
        }

        // atMost -= float
        do {
            var axis = SizeConstraint.Axis.atMost(60)

            axis /= 3

            XCTAssertEqual(axis, .atMost(20))
        }

    }

    func test_isGreaterThanZero() {

        XCTAssertFalse(SizeConstraint.Axis.atMost(-1).isGreaterThanZero)
        XCTAssertFalse(SizeConstraint.Axis.atMost(0).isGreaterThanZero)
        XCTAssertTrue(SizeConstraint.Axis.atMost(1).isGreaterThanZero)
        XCTAssertTrue(SizeConstraint.Axis.unconstrained.isGreaterThanZero)
    }
}
