import XCTest
@testable import BlueprintUI

class LayoutModeTests: XCTestCase {

    func testName() {
        // These names may end up being propagated as analytics properties,
        // so be aware that renaming them can impact existing queries/reports.
        XCTAssertEqual(LayoutMode.caffeinated.name, "Caffeinated")
        XCTAssertEqual(LayoutMode.legacy.name, "Legacy")
    }
}
