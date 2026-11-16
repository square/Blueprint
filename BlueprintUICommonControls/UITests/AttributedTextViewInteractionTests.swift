import XCTest

final class AttributedTextViewInteractionTests: XCTestCase {
    func test_multipleLinksActivateWithoutSelectionAndUseReplacementHandler() throws {
        try XCTSkipIf(ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 17)
        let app = XCUIApplication(bundleIdentifier: "com.squareup.blueprint.BlueprintUICommonControlsTestHost")
        app.launchArguments = ["-attributed-text-view", "-label-role"]
        app.launch()
        for title in ["Terms", "Privacy"] {
            let link = app.links[title]
            XCTAssertTrue(link.waitForExistence(timeout: 5))
            link.tap()
            XCTAssertEqual(app.staticTexts["result"].label, "Handler 1: https://example.com/" + title.lowercased())
        }
        app.buttons["Replace handler"].tap()
        app.links["Terms"].tap()
        XCTAssertEqual(app.staticTexts["result"].label, "Handler 2: https://example.com/terms")
    }

    func test_combinedTextUsesItsRoleAndPreservesExplicitValues() throws {
        try XCTSkipIf(ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 17)
        let app = XCUIApplication(bundleIdentifier: "com.squareup.blueprint.BlueprintUICommonControlsTestHost")
        for (arguments, label, value) in [
            (["-label-role"], "Terms Privacy", ""),
            ([], "", "Terms Privacy"),
            (["-label-role", "-explicit-value"], "Terms Privacy", "42 dollars"),
        ] {
            app.launchArguments = ["-attributed-text-view", "-combine"] + arguments
            app.launch()
            let combined = app.descendants(matching: .any)["composed"]
            XCTAssertTrue(combined.waitForExistence(timeout: 5))
            XCTAssertEqual(combined.label, label)
            XCTAssertEqual(combined.value as? String ?? "", value)
        }
    }

    func test_labelRolePreservesSeparateNativeListItems() throws {
        try XCTSkipIf(ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 17)
        let app = XCUIApplication(bundleIdentifier: "com.squareup.blueprint.BlueprintUICommonControlsTestHost")
        for role in [[], ["-label-role"]] {
            app.launchArguments = ["-attributed-text-view", "-native-list"] + role
            app.launch()
            for item in ["First item", "Second item", "Third item"] {
                XCTAssertTrue(app.staticTexts[item].waitForExistence(timeout: 5))
            }
        }
    }

    func test_disablingDetectionRemovesGeneratedLinkAndPreservesExplicitLink() throws {
        try XCTSkipIf(ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 17)
        let app = XCUIApplication(bundleIdentifier: "com.squareup.blueprint.BlueprintUICommonControlsTestHost")
        for (arguments, fragment) in [([], "/detected"), (["-detect-dates"], "2030")] {
            app.launchArguments = ["-attributed-text-view", "-detect-links"] + arguments
            app.launch()
            let detected = app.links.matching(NSPredicate(format: "label CONTAINS %@", fragment)).firstMatch
            XCTAssertTrue(detected.waitForExistence(timeout: 5))
            app.buttons["Disable detection"].tap()
            let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: detected)
            XCTAssertEqual(XCTWaiter.wait(for: [gone], timeout: 5), .completed)
            XCTAssertTrue(app.links["Terms"].exists)
        }
    }
}
