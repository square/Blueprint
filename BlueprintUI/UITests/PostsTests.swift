import XCTest

final class PostsTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testPostsFavesAndRTs() throws {
        let app = XCUIApplication()
        app.launch()

        app.buttons["Post List"].tap()

        let nameField = app.textFields["Name"]
        nameField.tap()

        let deleteString = String(
            repeating: XCUIKeyboardKey.delete.rawValue,
            count: (nameField.value as? String)?.count ?? 0
        )
        nameField.typeText(deleteString)

        nameField.typeText("jack")
        let commentField = app.textFields["Comment"]
        commentField.tap()

        commentField.typeText("just setting up my twttr")
        commentField.typeText("\n")

        XCTAssertTrue(app.staticTexts["just setting up my twttr"].exists)

        app.buttons["Fave @jack's Post"].tap()

        nameField.tap()
        let secondDelete = String(
            repeating: XCUIKeyboardKey.delete.rawValue,
            count: (nameField.value as? String)?.count ?? 0
        )
        nameField.typeText(secondDelete)
        nameField.typeText("Tristan")

        app.buttons["RT @jack's Post"].tap()
        XCTAssertTrue(app.staticTexts["RT: @jack just setting up my twttr"].exists)
    }
}
