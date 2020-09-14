import XCTest
@testable import BlueprintUI

class OpacityTests: XCTestCase {

    func test_measuring() {
        let element = Spacer()
        let transparent = element.opacity(0.88)

        let constraint = SizeConstraint(width: .unconstrained, height: .unconstrained)

        // Measurement should not be affected
        XCTAssertEqual(element.content.measure(in: constraint), transparent.content.measure(in: constraint))
    }

    func test_layout() {
        let element = Spacer()
        let transparent = element.opacity(0.88)

        let children = transparent.layout(frame: CGRect(x: 0, y: 0, width: 100, height: 100)).children.map { $0.node }

        XCTAssertEqual(children.count, 1)
        XCTAssertEqual(children[0].layoutAttributes.alpha, 0.88)
        XCTAssertEqual(children[0].layoutAttributes.frame, CGRect(x: 0, y: 0, width: 100, height: 100))
    }

}
