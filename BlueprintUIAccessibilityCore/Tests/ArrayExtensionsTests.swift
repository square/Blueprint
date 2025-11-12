import XCTest
@testable import BlueprintUIAccessibilityCore

class ArrayExtensionsTests: XCTestCase {

    func test_removingDuplicates() {
        let array = ["1", "2", "1", "3", "2"]
        let expectedArray = ["1", "2", "3"]
        XCTAssertEqual(array.removingDuplicates, expectedArray)
    }

    func test_joinedAccessibilityString() {

        let array = ["foo", "", "bar", nil, "baz"]
        let expectedString = "foo, bar, baz"

        XCTAssertEqual(array.joinedAccessibilityString(), expectedString)

        XCTAssertNil([String?]().joinedAccessibilityString())

        XCTAssertNil(["", nil, nil, ""].joinedAccessibilityString())

    }

}
