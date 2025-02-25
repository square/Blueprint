import XCTest

final class AccessibilityTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAccessibility() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["Accessibility"].tap()

        XCTAssertTrue(app.staticTexts["Blocker"].exists) // I cant believe there isn't am app.headers?
        XCTAssertFalse(app.staticTexts["Blocked label"].exists)

        XCTAssertTrue(app.staticTexts["Accessibility Element"].exists)
        XCTAssertTrue(app.staticTexts["Title"].value as? String == "Detail")
        XCTAssertTrue(app.staticTexts["This is an example of a long accessibility label"].value as? String == "Detail")
    }
}
