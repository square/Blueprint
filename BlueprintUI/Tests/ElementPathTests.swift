import XCTest
@testable import BlueprintUI

class ElementPathTests: XCTestCase {

    func test_equality() {

        XCTAssertEqual(ElementPath.empty, ElementPath.empty)

        let testPath = ElementPath().appending(identifier: ElementIdentifier(elementType: A.self, key: nil, count: 0))

        XCTAssertNotEqual(testPath, .empty)

        XCTAssertEqual(testPath, testPath)

    }

    func test_copyOnWrite() {

        let testPath = ElementPath().appending(identifier: ElementIdentifier(elementType: A.self, key: nil, count: 0))

        var otherPath = testPath
        otherPath.prepend(identifier: ElementIdentifier(elementType: B.self, key: nil, count: 1))

        XCTAssertNotEqual(testPath, otherPath)
    }

    func test_empty() {
        XCTAssertEqual(ElementPath.empty.identifiers, [])
    }

}


fileprivate struct A: Element {

    var content: ElementContent {
        return ElementContent(intrinsicSize: .zero)
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }

}

fileprivate struct B: Element {

    var content: ElementContent {
        return ElementContent(intrinsicSize: .zero)
    }

    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }
    
}
