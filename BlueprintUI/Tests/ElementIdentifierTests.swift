import XCTest
@testable import BlueprintUI

class ElementIdentifierTests: XCTestCase {

    func test_equality() {

        XCTAssertEqual(ElementIdentifier.index(0), ElementIdentifier.index(0))
        XCTAssertNotEqual(ElementIdentifier.index(0), ElementIdentifier.index(1))

        XCTAssertEqual(ElementIdentifier.key("asdf"), ElementIdentifier.key("asdf"))
        XCTAssertNotEqual(ElementIdentifier.key("foo"), ElementIdentifier.key("bar"))

        XCTAssertNotEqual(ElementIdentifier.index(0), ElementIdentifier.key("0"))

    }

    func test_convenienceProperties() {
        XCTAssertNil(ElementIdentifier.index(0).key)
        XCTAssertEqual(ElementIdentifier.key("asdf").key, "asdf")
    }

}

