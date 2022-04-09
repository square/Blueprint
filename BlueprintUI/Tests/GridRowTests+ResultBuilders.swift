import XCTest
@testable import BlueprintUI

class GridRowTestsResultBuilders: XCTestCase {
    func test_resultBuilder() {
        let gridRow = GridRow {
            TestElement()
            TestElement2()
                .gridRowChild(key: "test", width: .absolute(100))
        }

        XCTAssertEqual(gridRow.children[0].key, nil)
        XCTAssertEqual(gridRow.children[0].width, .proportional(1))
        XCTAssert(type(of: gridRow.children[0].element) == TestElement.self)

        XCTAssertEqual(gridRow.children[1].key, "test")
        XCTAssertEqual(gridRow.children[1].width, .absolute(100))
        XCTAssert(type(of: gridRow.children[1].element) == TestElement2.self)
    }
}

private struct TestElement: Element {
    var size: CGSize

    init(size: CGSize = .zero) {
        self.size = size
    }

    var content: ElementContent {
        ElementContent(intrinsicSize: size)
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
}


private struct TestElement2: Element {
    var size: CGSize

    init(size: CGSize = .zero) {
        self.size = size
    }

    var content: ElementContent {
        ElementContent(intrinsicSize: size)
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
}
