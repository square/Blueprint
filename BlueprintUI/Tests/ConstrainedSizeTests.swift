import XCTest
@testable import BlueprintUI

class ConstrainedSizeTests: XCTestCase {

    func test_unconstrained() {
        let constraint = SizeConstraint(width: .unconstrained, height: .unconstrained)
        let environment = Environment()

        XCTAssertEqual(
            ConstrainedSize(wrapping: TestElement()).content.measure(in: constraint, environment: environment).width,
            100
        )

        XCTAssertEqual(
            ConstrainedSize(wrapping: TestElement()).content.measure(in: constraint, environment: environment).height,
            100
        )
    }

    func test_atMost() {
        let constraint = SizeConstraint(width: .unconstrained, height: .unconstrained)
        let environment = Environment()

        XCTAssertEqual(
            ConstrainedSize(width: .atMost(75), wrapping: TestElement()).content.measure(in: constraint, environment: environment).width,
            75
        )

        XCTAssertEqual(
            ConstrainedSize(height: .atMost(75), wrapping: TestElement()).content.measure(in: constraint, environment: environment).height,
            75
        )
    }

    func test_atLeast() {
        let constraint = SizeConstraint(width: .unconstrained, height: .unconstrained)
        let environment = Environment()

        XCTAssertEqual(
            ConstrainedSize(width: .atLeast(175), wrapping: TestElement()).content.measure(in: constraint, environment: environment).width,
            175
        )

        XCTAssertEqual(
            ConstrainedSize(height: .atLeast(175), wrapping: TestElement()).content.measure(in: constraint, environment: environment).height,
            175
        )
    }

    func test_withinRange() {
        let constraint = SizeConstraint(width: .unconstrained, height: .unconstrained)
        let environment = Environment()

        XCTAssertEqual(
            ConstrainedSize(width: .within(0...13), wrapping: TestElement()).content.measure(in: constraint, environment: environment).width,
            13
        )

        XCTAssertEqual(
            ConstrainedSize(height: .within(0...13), wrapping: TestElement()).content.measure(in: constraint, environment: environment).height,
            13
        )
    }

    func test_absolute() {
        let constraint = SizeConstraint(width: .unconstrained, height: .unconstrained)
        let environment = Environment()

        XCTAssertEqual(
            ConstrainedSize(width: .absolute(49), wrapping: TestElement()).content.measure(in: constraint, environment: environment).width,
            49
        )

        XCTAssertEqual(
            ConstrainedSize(height: .absolute(49), wrapping: TestElement()).content.measure(in: constraint, environment: environment).height,
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
