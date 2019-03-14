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

        let children = centered
            .layout(frame: CGRect(x: 0, y: 0, width: 5000, height: 6000))
            .children
            .map { $0.node }

        XCTAssertEqual(children.count, 1)
        XCTAssertEqual(children[0].layoutAttributes.center, CGPoint(x: 2500, y: 3000))
        XCTAssertEqual(children[0].layoutAttributes.bounds, CGRect(x: 0, y: 0, width: 123, height: 456))
        XCTAssertTrue(children[0].element is TestElement)
    }

}


fileprivate struct TestElement: Element {

    var content: ElementContent {
        return ElementContent(intrinsicSize: CGSize(width: 123, height: 456))
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }

}
