import XCTest
@testable import BlueprintUI


class CenteredTests: XCTestCase {

    func test_measuring() {
        let constraint = SizeConstraint(width: .unconstrained, height: .unconstrained)
        let element = TestElement()
        let centered = Centered(element)
        XCTAssertEqual(centered.content.size(in: constraint), element.content.size(in: constraint))
    }

    func test_layout() {
        let element = TestElement()
        let centered = Centered(element)

        let layout = centered.layout(frame: CGRect(x: 0, y: 0, width: 5000, height: 6000))
        if let child = findLayout(of: TestElement.self, in: layout) {
            XCTAssertEqual(
                child.layoutAttributes.frame,
                CGRect(
                    x: 2439,
                    y: 2772,
                    width: 123,
                    height: 456))
        } else {
            XCTFail("TestElement should be a child element")
        }
    }

    private func findLayout(of elementType: Element.Type, in node: LayoutResultNode) -> LayoutResultNode? {
        if type(of: node.element) == elementType {
            return node
        }

        for child in node.children {
            if let node = findLayout(of: elementType, in: child.node) {
                return node
            }
        }
        return nil
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
