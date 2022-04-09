import XCTest
@testable import BlueprintUI


class CenteredTests: XCTestCase {

    func test_measuring() {
        let constraint = SizeConstraint(width: .unconstrained, height: .unconstrained)
        let element = TestElement()
        let centered = Centered(element)
        XCTAssertEqual(centered.content.measure(in: constraint), element.content.measure(in: constraint))
    }

    func test_layout() {
        let element = TestElement()
        let centered = Centered(element)

        let layout = centered.layout(frame: CGRect(x: 0, y: 0, width: 5000, height: 6000))

        if let child = layout.findLayout(of: TestElement.self) {
            XCTAssertEqual(
                child.layoutAttributes.frame,
                CGRect(
                    x: 2438.5,
                    y: 2772,
                    width: 123,
                    height: 456
                )
            )
        } else {
            XCTFail("TestElement should be a child element")
        }
    }
}


fileprivate struct TestElement: Element {

    var content: ElementContent {
        ElementContent(intrinsicSize: CGSize(width: 123, height: 456))
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }

}
