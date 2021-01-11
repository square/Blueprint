import XCTest
@testable import BlueprintUI

class TransformedTests: XCTestCase {

    func test_measuring() {
        let element = Spacer()
        let translated = element.translated(translateX: 50, translateY: 50)
        let rotated = element.rotated(by: Measurement(value: 90, unit: .degrees))
        let scaled = element.scaled(scaleX: 1.2, scaleY: 0.8)
        let constraint = SizeConstraint(width: .unconstrained, height: .unconstrained)

        // Measurement should not be affected
        XCTAssertEqual(element.content.measure(in: constraint), translated.content.measure(in: constraint))
        XCTAssertEqual(element.content.measure(in: constraint), rotated.content.measure(in: constraint))
        XCTAssertEqual(element.content.measure(in: constraint), scaled.content.measure(in: constraint))
    }

    func test_layout() {
        let element = Spacer()
        let translated = element.translated(translateX: 50, translateY: 50)
        let rotated = element.rotated(by: Measurement(value: 90, unit: .degrees))
        let scaled = element.scaled(scaleX: 1.2, scaleY: 0.8)

        for element in [translated, rotated, scaled] {
            let children = element.layout(frame: CGRect(x: 0, y: 0, width: 100, height: 100)).children.map { $0.node }

            XCTAssertEqual(children.count, 1)
            XCTAssertEqual(children[0].layoutAttributes.transform, element.transform)
            XCTAssertEqual(children[0].layoutAttributes.frame, CGRect(x: 0, y: 0, width: 100, height: 100))
        }
    }

}
