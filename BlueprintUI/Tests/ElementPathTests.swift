import XCTest
@testable import BlueprintUI

class ElementPathTests: XCTestCase {

    func test_equality() {

        XCTAssertEqual(ElementPath.empty, ElementPath.empty)

        let testPath = ElementPath.init().appending(component: ElementPath.Component(elementType: A.self, identifier: .index(0)))

        XCTAssertNotEqual(testPath, .empty)

        XCTAssertEqual(testPath, testPath)

    }

    func test_copyOnWrite() {

        let testPath = ElementPath.init().appending(component: ElementPath.Component(elementType: A.self, identifier: .index(0)))

        var otherPath = testPath
        otherPath.prepend(component: ElementPath.Component(elementType: B.self, identifier: .key("asdf")))

        XCTAssertNotEqual(testPath, otherPath)
    }

    func test_empty() {
        XCTAssertEqual(ElementPath.empty.components, [])
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
