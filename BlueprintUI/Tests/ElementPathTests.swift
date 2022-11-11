import XCTest
@testable import BlueprintUI

class ElementPathTests: XCTestCase {

    func test_equality() {

        XCTAssertEqual(ElementPath.empty, ElementPath.empty)

        let testPath = ElementPath().appending(identifier: ElementIdentifier.identifier(for: A(), key: nil, count: 0))

        XCTAssertNotEqual(testPath, .empty)

        XCTAssertEqual(testPath, testPath)

    }

    func test_copyOnWrite() {

        let testPath = ElementPath().appending(identifier: ElementIdentifier.identifier(for: A(), key: nil, count: 0))

        var otherPath = testPath
        otherPath.prepend(identifier: ElementIdentifier.identifier(for: B(), key: nil, count: 1))

        XCTAssertNotEqual(testPath, otherPath)
    }

    func test_empty() {
        XCTAssertEqual(ElementPath.empty.identifiers, [])
    }

}


fileprivate struct A: Element {

    var content: ElementContent {
        ElementContent(intrinsicSize: .zero)
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }

}

fileprivate struct B: Element {

    var content: ElementContent {
        ElementContent(intrinsicSize: .zero)
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }

}
