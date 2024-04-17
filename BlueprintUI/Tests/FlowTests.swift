import XCTest
@testable import BlueprintUI


class FlowTests: XCTestCase {

    func test_measurement() {

        ///
        /// Zero size tests
        ///

        XCTAssertEqual(Flow {}.content.measure(in: .unconstrained), .zero)
        XCTAssertEqual(Flow {}.content.measure(in: .init(CGSize(width: 10, height: 10))), .zero)

        ///
        /// One element tests
        ///

        let one = Flow {
            ConstrainedSize(width: 50, height: 5)
        }

        XCTAssertEqual(
            one.content.measure(in: .unconstrained),
            CGSize(width: 50, height: 5)
        )

        /// Note: We don't manually constrain measured elements to the size of
        /// the input constraint, similar to stacks and other elements.

        XCTAssertEqual(
            one.content.measure(in: .init(CGSize(width: 40, height: 4))),
            CGSize(width: 50, height: 5)
        )

        ///
        /// Multiple element tests
        ///

        let multiple = Flow {
            ConstrainedSize(width: 50, height: 5)
            ConstrainedSize(width: 100, height: 5).flowChild(key: "aKey")
            ConstrainedSize(width: 50, height: 5)
        }

        XCTAssertEqual(
            multiple.content.measure(in: .init(width: 110)),
            CGSize(width: 100, height: 15)
        )
    }
}


extension ConstrainedSize {

    fileprivate init(width: CGFloat, height: CGFloat) {
        self = Self(width: .absolute(width), height: .absolute(height), wrapping: Empty())
    }

}
