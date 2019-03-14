import XCTest
@testable import Blueprint

class InsetTests: XCTestCase {

    func test_measuring() {
        let element = TestElement()
        let inset = Inset(wrapping: element, uniformInset: 20.0)

        let constraint = SizeConstraint(width: .unconstrained, height: .unconstrained)

        XCTAssertEqual(element.content.measure(in: constraint).width + 40, inset.content.measure(in: constraint).width)
        XCTAssertEqual(element.content.measure(in: constraint).height + 40, inset.content.measure(in: constraint).height)
    }

    func test_layout() {
        let element = TestElement()
        let inset = Inset(wrapping: element, uniformInset: 20.0)

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
