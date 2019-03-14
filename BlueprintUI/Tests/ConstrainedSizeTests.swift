import XCTest
import BlueprintUI

class ConstrainedSizeTests: XCTestCase {

    func test_unconstrained() {
        let constraint = SizeConstraint(width: .unconstrained, height: .unconstrained)

        XCTAssertEqual(
            ConstrainedSize(wrapping: TestElement()).content.measure(in: constraint).width,
            100
        )

        XCTAssertEqual(
            ConstrainedSize(wrapping: TestElement()).content.measure(in: constraint).height,
            100
        )
    }

    func test_atMost() {
        let constraint = SizeConstraint(width: .unconstrained, height: .unconstrained)

        XCTAssertEqual(
            ConstrainedSize(wrapping: TestElement(), width: .atMost(75)).content.measure(in: constraint).width,
            75
        )

        XCTAssertEqual(
            ConstrainedSize(wrapping: TestElement(), height: .atMost(75)).content.measure(in: constraint).height,
            75
        )
    }

    func test_atLeast() {
        let constraint = SizeConstraint(width: .unconstrained, height: .unconstrained)

        XCTAssertEqual(
            ConstrainedSize(wrapping: TestElement(), width: .atLeast(175)).content.measure(in: constraint).width,
            175
        )

        XCTAssertEqual(
            ConstrainedSize(wrapping: TestElement(), height: .atLeast(175)).content.measure(in: constraint).height,
            175
        )
    }

    func test_withinRange() {
        let constraint = SizeConstraint(width: .unconstrained, height: .unconstrained)

        XCTAssertEqual(
            ConstrainedSize(wrapping: TestElement(), width: .within(0...13)).content.measure(in: constraint).width,
            13
        )

        XCTAssertEqual(
            ConstrainedSize(wrapping: TestElement(), height: .within(0...13)).content.measure(in: constraint).height,
            13
        )
    }

    func test_absolute() {
        let constraint = SizeConstraint(width: .unconstrained, height: .unconstrained)

        XCTAssertEqual(
            ConstrainedSize(wrapping: TestElement(), width: .absolute(49)).content.measure(in: constraint).width,
            49
        )

        XCTAssertEqual(
            ConstrainedSize(wrapping: TestElement(), height: .absolute(49)).content.measure(in: constraint).height,
            49
        )
    }

}


fileprivate struct TestElement: Element {

    var content: ElementContent {
        return ElementContent(intrinsicSize: CGSize(width: 100, height: 100))
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }

}
