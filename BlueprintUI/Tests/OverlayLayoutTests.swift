import XCTest
@testable import BlueprintUI

class OverlayTests: XCTestCase {

    func test_measuring() {
        let overlay = Overlay(elements: [
            TestElement(size: CGSize(width: 200, height: 200)),
            TestElement(size: CGSize(width: 100, height: 100)),
            TestElement(size: CGSize(width: 50, height: 50)),
        ])
        XCTAssertEqual(overlay.content.measure(in: .unconstrained), CGSize(width: 200, height: 200))
    }

    func test_layout() {
        let overlay = Overlay(elements: [
            TestElement(size: CGSize(width: 200, height: 200)),
            TestElement(size: CGSize(width: 100, height: 100)),
            TestElement(size: CGSize(width: 50, height: 50)),
        ])
        XCTAssertEqual(
            overlay
                .layout(frame: CGRect(x: 0, y: 0, width: 456, height: 789))
                .children
                .map { $0.node.layoutAttributes.frame },
            Array(repeating: CGRect(x: 0, y: 0, width: 456, height: 789), count: 3)
        )
    }

    func test_keys() {
        struct Test1: ProxyElement { var elementRepresentation: Element = Empty() }
        struct Test2: ProxyElement { var elementRepresentation: Element = Empty() }
        struct Test3: ProxyElement { var elementRepresentation: Element = Empty() }

        let element = Overlay { overlay in
            overlay.add(key: AnyHashable(1), child: Test1())
            overlay.add(key: AnyHashable("foo"), child: Test2())
            overlay.add(child: Test3())
        }

        XCTAssertEqual(element.children[0].key, AnyHashable(1))
        XCTAssert(type(of: element.children[0].element) == Test1.self)

        XCTAssertEqual(element.children[1].key, AnyHashable("foo"))
        XCTAssert(type(of: element.children[1].element) == Test2.self)

        XCTAssertEqual(element.children[2].key, nil)
        XCTAssert(type(of: element.children[2].element) == Test3.self)
    }

}


fileprivate struct TestElement: Element {

    var size: CGSize

    init(size: CGSize = CGSize(width: 100, height: 100)) {
        self.size = size
    }

    var content: ElementContent {
        ElementContent(intrinsicSize: size)
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }

}
