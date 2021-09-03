import BlueprintUI
import XCTest

class ConstrainedSizeTests: XCTestCase {

    func test_in_unconstrained() {
        let constraint = SizeConstraint(width: .unconstrained, height: .unconstrained)

        // Unconstrained

        do {
            let fixed = ConstrainedSize(wrapping: FixedElement())
            let flexible = ConstrainedSize(wrapping: FlexibleElement())

            XCTAssertEqual(
                CGSize(width: 100, height: 110),
                fixed.content.measure(in: constraint)
            )

            XCTAssertEqual(
                CGSize(width: 100, height: 110),
                flexible.content.measure(in: constraint)
            )
        }

        // atMost - width only

        do {
            let fixed = ConstrainedSize(width: .atMost(75), wrapping: FixedElement())
            let flexible = ConstrainedSize(width: .atMost(75), wrapping: FlexibleElement())

            XCTAssertEqual(
                CGSize(width: 75, height: 110),
                fixed.content.measure(in: constraint)
            )

            XCTAssertEqual(
                CGSize(width: 75, height: 147),
                flexible.content.measure(in: constraint)
            )
        }

        // atMost

        do {
            let fixed = ConstrainedSize(width: .atMost(75), height: .atMost(85), wrapping: FixedElement())
            let flexible = ConstrainedSize(width: .atMost(75), height: .atMost(85), wrapping: FlexibleElement())

            XCTAssertEqual(
                CGSize(width: 75, height: 85),
                fixed.content.measure(in: constraint)
            )

            XCTAssertEqual(
                CGSize(width: 75, height: 85),
                flexible.content.measure(in: constraint)
            )
        }

        // atLeast - width only

        do {
            let fixed = ConstrainedSize(width: .atLeast(175), wrapping: FixedElement())
            let flexible = ConstrainedSize(width: .atLeast(175), wrapping: FlexibleElement())

            XCTAssertEqual(
                CGSize(width: 175, height: 110),
                fixed.content.measure(in: constraint)
            )

            XCTAssertEqual(
                CGSize(width: 175, height: 110),
                flexible.content.measure(in: constraint)
            )
        }

        // atLeast

        do {
            let fixed = ConstrainedSize(width: .atLeast(175), height: .atLeast(150), wrapping: FixedElement())
            let flexible = ConstrainedSize(width: .atLeast(175), height: .atLeast(150), wrapping: FlexibleElement())

            XCTAssertEqual(
                CGSize(width: 175, height: 150),
                fixed.content.measure(in: constraint)
            )

            XCTAssertEqual(
                CGSize(width: 175, height: 150),
                flexible.content.measure(in: constraint)
            )
        }

        // withinRange - width only

        do {
            let fixed = ConstrainedSize(width: .within(110...120), wrapping: FixedElement())
            let flexible = ConstrainedSize(width: .within(110...120), wrapping: FlexibleElement())

            XCTAssertEqual(
                CGSize(width: 110, height: 110),
                fixed.content.measure(in: constraint)
            )

            XCTAssertEqual(
                CGSize(width: 120, height: 92),
                flexible.content.measure(in: constraint)
            )
        }

        // withinRange

        do {
            let fixed = ConstrainedSize(width: .within(110...120), height: .within(120...130), wrapping: FixedElement())
            let flexible = ConstrainedSize(
                width: .within(110...120),
                height: .within(120...130),
                wrapping: FlexibleElement()
            )

            XCTAssertEqual(
                CGSize(width: 110, height: 120),
                fixed.content.measure(in: constraint)
            )

            XCTAssertEqual(
                CGSize(width: 120, height: 120),
                flexible.content.measure(in: constraint)
            )
        }

        // absolute - width only

        do {
            let fixed = ConstrainedSize(width: .absolute(125), wrapping: FixedElement())
            let flexible = ConstrainedSize(width: .absolute(125), wrapping: FlexibleElement())

            XCTAssertEqual(
                CGSize(width: 125, height: 110),
                fixed.content.measure(in: constraint)
            )

            XCTAssertEqual(
                CGSize(width: 125, height: 88),
                flexible.content.measure(in: constraint)
            )
        }

        // absolute

        do {
            let fixed = ConstrainedSize(width: .absolute(125), height: .absolute(135), wrapping: FixedElement())
            let flexible = ConstrainedSize(width: .absolute(125), height: .absolute(135), wrapping: FlexibleElement())

            XCTAssertEqual(
                CGSize(width: 125, height: 135),
                fixed.content.measure(in: constraint)
            )

            XCTAssertEqual(
                CGSize(width: 125, height: 135),
                flexible.content.measure(in: constraint)
            )
        }
    }

    func test_in_atMost() {
        let constraint = SizeConstraint(width: .atMost(75.0), height: .atMost(300.0))

        // Unconstrained

        do {
            let fixed = ConstrainedSize(wrapping: FixedElement())
            let flexible = ConstrainedSize(wrapping: FlexibleElement())

            XCTAssertEqual(
                CGSize(width: 100, height: 110),
                fixed.content.measure(in: constraint)
            )

            XCTAssertEqual(
                CGSize(width: 75, height: 147),
                flexible.content.measure(in: constraint)
            )
        }

        // atMost - width only

        do {
            let fixed = ConstrainedSize(width: .atMost(85), wrapping: FixedElement())
            let flexible = ConstrainedSize(width: .atMost(85), wrapping: FlexibleElement())

            XCTAssertEqual(
                CGSize(width: 85, height: 110),
                fixed.content.measure(in: constraint)
            )

            XCTAssertEqual(
                CGSize(width: 75, height: 147),
                flexible.content.measure(in: constraint)
            )
        }

        // atMost

        do {
            let fixed = ConstrainedSize(width: .atMost(85), height: .atMost(85), wrapping: FixedElement())
            let flexible = ConstrainedSize(width: .atMost(85), height: .atMost(85), wrapping: FlexibleElement())

            XCTAssertEqual(
                CGSize(width: 85, height: 85),
                fixed.content.measure(in: constraint)
            )

            XCTAssertEqual(
                CGSize(width: 75, height: 85),
                flexible.content.measure(in: constraint)
            )
        }

        // atLeast - width only

        do {
            let fixed = ConstrainedSize(width: .atLeast(175), wrapping: FixedElement())
            let flexible = ConstrainedSize(width: .atLeast(175), wrapping: FlexibleElement())

            XCTAssertEqual(
                CGSize(width: 175, height: 110),
                fixed.content.measure(in: constraint)
            )

            XCTAssertEqual(
                CGSize(width: 175, height: 63),
                flexible.content.measure(in: constraint)
            )
        }

        // atLeast

        do {
            let fixed = ConstrainedSize(width: .atLeast(175), height: .atLeast(150), wrapping: FixedElement())
            let flexible = ConstrainedSize(width: .atLeast(175), height: .atLeast(150), wrapping: FlexibleElement())

            XCTAssertEqual(
                CGSize(width: 175, height: 150),
                fixed.content.measure(in: constraint)
            )

            XCTAssertEqual(
                CGSize(width: 175, height: 150),
                flexible.content.measure(in: constraint)
            )
        }

        // withinRange - width only

        do {
            let fixed = ConstrainedSize(width: .within(110...120), wrapping: FixedElement())
            let flexible = ConstrainedSize(width: .within(110...120), wrapping: FlexibleElement())

            XCTAssertEqual(
                CGSize(width: 110, height: 110),
                fixed.content.measure(in: constraint)
            )

            XCTAssertEqual(
                CGSize(width: 110, height: 100),
                flexible.content.measure(in: constraint)
            )
        }

        // withinRange

        do {
            let fixed = ConstrainedSize(width: .within(110...120), height: .within(120...130), wrapping: FixedElement())
            let flexible = ConstrainedSize(
                width: .within(110...120),
                height: .within(120...130),
                wrapping: FlexibleElement()
            )

            XCTAssertEqual(
                CGSize(width: 110, height: 120),
                fixed.content.measure(in: constraint)
            )

            XCTAssertEqual(
                CGSize(width: 110, height: 120),
                flexible.content.measure(in: constraint)
            )
        }

        // absolute - width only

        do {
            let fixed = ConstrainedSize(width: .absolute(125), wrapping: FixedElement())
            let flexible = ConstrainedSize(width: .absolute(125), wrapping: FlexibleElement())

            XCTAssertEqual(
                CGSize(width: 125, height: 110),
                fixed.content.measure(in: constraint)
            )

            XCTAssertEqual(
                CGSize(width: 125, height: 88),
                flexible.content.measure(in: constraint)
            )
        }

        // absolute

        do {
            let fixed = ConstrainedSize(width: .absolute(125), height: .absolute(135), wrapping: FixedElement())
            let flexible = ConstrainedSize(width: .absolute(125), height: .absolute(135), wrapping: FlexibleElement())

            XCTAssertEqual(
                CGSize(width: 125, height: 135),
                fixed.content.measure(in: constraint)
            )

            XCTAssertEqual(
                CGSize(width: 125, height: 135),
                flexible.content.measure(in: constraint)
            )
        }
    }
}



fileprivate struct FixedElement: Element {

    var content: ElementContent {
        ElementContent { constraint -> CGSize in
            // Using different sizes for width and height in case
            // any internal calculations mix up x and y; we'll catch that.

            CGSize(width: 100, height: 110)
        }
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
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

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
}
