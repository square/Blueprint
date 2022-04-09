import XCTest
@testable import BlueprintUI

class OverlayTestsResultBuilders: XCTestCase {
    func test_resultBuilder() {
        let overlay = Overlay {
            TestElement()
            TestElement2().overlayChild(key: "foo")
            TestElement2().keyed("bar")
        }

        XCTAssert(type(of: overlay.children[0].element) == TestElement.self)
        XCTAssertNil(overlay.children[0].key)
        XCTAssert(type(of: overlay.children[1].element) == TestElement2.self)
        XCTAssertEqual(overlay.children[1].key, "foo")
        XCTAssert(type(of: overlay.children[2].element) == TestElement2.self)
        XCTAssertEqual(overlay.children[2].key, "bar")
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

fileprivate struct TestElement2: Element {

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
