import XCTest
@testable import BlueprintUI

class InsetTests: XCTestCase {

    func test_measuring() {
        let element = TestElement()
        let inset = Inset(uniformInset: 20.0, wrapping: element)

        let constraint = SizeConstraint(width: .unconstrained, height: .unconstrained)

        let contentSize = element.content.measure(in: constraint, environment: .empty)
        let insetSize = inset.content.measure(in: constraint, environment: .empty)

        XCTAssertEqual(contentSize.width + 40, insetSize.width)
        XCTAssertEqual(contentSize.height + 40, insetSize.height)
    }

    func test_layout() {
        let element = TestElement()
        let inset = Inset(uniformInset: 20.0, wrapping: element)

        let children = inset.layout(frame: CGRect(x: 0, y: 0, width: 100, height: 100)).children.map { $0.node }

        XCTAssertEqual(children.count, 1)
        XCTAssertEqual(children[0].layoutAttributes.frame, CGRect(x: 20, y: 20, width: 60, height: 60))
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
