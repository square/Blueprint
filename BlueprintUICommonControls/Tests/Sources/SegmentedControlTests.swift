import BlueprintUI
import XCTest
@testable import BlueprintUICommonControls

class SegmentedControlTests: XCTestCase {
    func test_resultBuilder() {
        let control = SegmentedControl {
            SegmentedControl.Item(title: "First", onSelect: {})
            SegmentedControl.Item(title: "Second", onSelect: {})
        }

        XCTAssertEqual(control.items[0].title, "First")
        XCTAssertEqual(control.items[1].title, "Second")
    }
}
