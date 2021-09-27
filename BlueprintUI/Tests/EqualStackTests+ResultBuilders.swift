import XCTest
@testable import BlueprintUI

class EqualStackTestsResultBuilders: XCTestCase {
    func test_resultBuilder() {
        let equalStack = EqualStack(direction: .horizontal, spacing: 3) {
            TestElement()
            TestElement2()
        }

        XCTAssert(type(of: equalStack.children[0]) == TestElement.self)
        XCTAssert(type(of: equalStack.children[1]) == TestElement2.self)
        XCTAssertEqual(equalStack.direction, .horizontal)
        XCTAssertEqual(equalStack.spacing, 3)
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
