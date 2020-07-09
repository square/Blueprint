
import BlueprintUI
import XCTest


class FillTests : XCTestCase {

    func test_both_in_unconstrained() {
        
        let constraint = SizeConstraint(width: .unconstrained, height: .unconstrained)
        let fixed = Fill(wrapping: FixedElement())
        XCTAssertEqual(
            fixed.content.measure(in: constraint, environment: .empty),
            CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        )

        let flexible = Fill(wrapping: FlexibleElement())
        XCTAssertEqual(
            flexible.content.measure(in: constraint, environment: .empty),
            CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        )
    }

    func test_horizontal_in_unconstrained() {
        
        let constraint = SizeConstraint(width: .unconstrained, height: .unconstrained)
        let fixed = Fill(along: .horizontal, wrapping: FixedElement())
        XCTAssertEqual(
            fixed.content.measure(in: constraint, environment: .empty),
            CGSize(width: CGFloat.greatestFiniteMagnitude, height: 110)
        )

        let flexible = Fill(along: .horizontal, wrapping: FlexibleElement())
        XCTAssertEqual(
            flexible.content.measure(in: constraint, environment: .empty),
            CGSize(width: CGFloat.greatestFiniteMagnitude, height: 110)
        )
    }

    func test_vertical_in_unconstrained() {
        
        let constraint = SizeConstraint(width: .unconstrained, height: .unconstrained)
        let fixed = Fill(along: .vertical, wrapping: FixedElement())
        XCTAssertEqual(
            fixed.content.measure(in: constraint, environment: .empty),
            CGSize(width: 100, height: CGFloat.greatestFiniteMagnitude)
        )

        let flexible = Fill(along: .vertical, wrapping: FlexibleElement())
        XCTAssertEqual(
            flexible.content.measure(in: constraint, environment: .empty),
            CGSize(width: 100, height: CGFloat.greatestFiniteMagnitude)
        )
    }

    func test_both_in_atMost() {
        
        let constraint = SizeConstraint(width: .atMost(600), height: .atMost(500))
        let fixed = Fill(wrapping: FixedElement())
        XCTAssertEqual(
            fixed.content.measure(in: constraint, environment: .empty),
            CGSize(width: 600, height: 500)
        )

        let flexible = Fill(wrapping: FlexibleElement())
        XCTAssertEqual(
            flexible.content.measure(in: constraint, environment: .empty),
            CGSize(width: 600, height: 500)
        )
    }

    func test_horizontal_in_atMost() {
        
        let constraint = SizeConstraint(width: .atMost(600), height: .atMost(500))
        let fixed = Fill(along: .horizontal, wrapping: FixedElement())
        XCTAssertEqual(
            fixed.content.measure(in: constraint, environment: .empty),
            CGSize(width: 600, height: 110)
        )

        let flexible = Fill(along: .horizontal, wrapping: FlexibleElement())
        XCTAssertEqual(
            flexible.content.measure(in: constraint, environment: .empty),
            CGSize(width: 600, height: 18)
        )
    }

    func test_vertical_in_atMost() {
        
        let constraint = SizeConstraint(width: .atMost(600), height: .atMost(500))
        let fixed = Fill(along: .vertical, wrapping: FixedElement())
        XCTAssertEqual(
            fixed.content.measure(in: constraint, environment: .empty),
            CGSize(width: 100, height: 500)
        )

        let flexible = Fill(along: .vertical, wrapping: FlexibleElement())
        XCTAssertEqual(
            flexible.content.measure(in: constraint, environment: .empty),
            CGSize(width: 600, height: 500)
        )
    }
}

// MARK: Test Helpers

fileprivate struct FixedElement: Element {

    var content: ElementContent {
        // Using different sizes for width and height in case
        // any internal calculations mix up x and y; we'll catch that.
        ElementContent(intrinsicSize: CGSize(width: 100, height: 110))
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }
}


fileprivate struct FlexibleElement: Element {

    var content: ElementContent {
        ElementContent { constraint -> CGSize in
            let totalArea: CGFloat = 100 * 110

            let width: CGFloat

            switch constraint.width {
            case .atMost(let max): width = max
            case .unconstrained: width = 100
            }

            return CGSize(width: width, height: round(totalArea / width))
        }
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }
}
