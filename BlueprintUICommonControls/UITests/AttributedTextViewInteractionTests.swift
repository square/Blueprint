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

    func test_combinedSingleLinkRetainsTouchInteractionWithHeader() throws {
        try XCTSkipIf(ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 17)
        let app = XCUIApplication(bundleIdentifier: "com.squareup.blueprint.BlueprintUICommonControlsTestHost")
        for extra in [[], ["-heading"]] {
            app.launchArguments = ["-attributed-text-view", "-single-link", "-label-role", "-combine"] + extra
            app.launch()
            let link = app.descendants(matching: .any)["composed"]
            XCTAssertTrue(link.waitForExistence(timeout: 5))
            link.tap()
            XCTAssertEqual(app.staticTexts["result"].label, "Handler 1: https://example.com/terms")
        }
    }

    func test_combinedLinkAccessibilityActivationMatchesUIKitWithHeader() throws {
        try XCTSkipIf(ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 17)
        let app = XCUIApplication(bundleIdentifier: "com.squareup.blueprint.BlueprintUICommonControlsTestHost")
        for heading in [false, true] {
            var outcomes: [String] = []
            for reference in [true, false] {
                app.launchArguments = ["-attributed-text-view", "-single-link", "-label-role", "-combine"]
                    + (heading ? ["-heading"] : []) + (reference ? ["-uikit-reference"] : [])
                app.launch()
                let link = app.descendants(matching: .any)["composed"]
                XCTAssertTrue(link.waitForExistence(timeout: 5))
                app.buttons["Activate accessibility"].tap()
                let result = app.staticTexts["result"]
                XCTAssertNotEqual(result.label, "Ready")
                outcomes.append(result.label)
                if result.label.hasPrefix("Native fallback") {
                    XCTAssertEqual(result.label, "Native fallback; link=true; header=\(heading)")
                    link.tap()
                    XCTAssertEqual(
                        result.label,
                        "Handler 1: https://example.com/terms",
                        "Reference: \(reference), heading: \(heading)"
                    )
                } else {
                    XCTAssertEqual(result.label, "Handler 1: https://example.com/terms")
                }
            }
            // A false native result leaves activation to UIKit's fallback; touch is tested separately.
            XCTAssertEqual(outcomes[0], outcomes[1], "Heading: \(heading)")
        }
    }

    func test_combinedTextUsesItsRoleAndPreservesExplicitValues() throws {
        try XCTSkipIf(ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 17)
        let app = XCUIApplication(bundleIdentifier: "com.squareup.blueprint.BlueprintUICommonControlsTestHost")
        for (arguments, label, value) in [
            (["-label-role"], "Terms Privacy", ""),
            ([], "", "Terms Privacy"),
            (["-label-role", "-explicit-value"], "Terms Privacy", "42 dollars"),
            (["-label-role", "-single-link"], "Terms", ""),
        ] {
            app.launchArguments = ["-attributed-text-view", "-combine"] + arguments
            app.launch()
            let combined = app.descendants(matching: .any)["composed"]
            XCTAssertTrue(combined.waitForExistence(timeout: 5))
            XCTAssertEqual(combined.label, label)
            XCTAssertEqual(combined.value as? String ?? "", value)
        }
    }

    func test_customContainerKeepsLinkedLabelAndItsOwnValue() throws {
        try XCTSkipIf(ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 17)
        let app = XCUIApplication(bundleIdentifier: "com.squareup.blueprint.BlueprintUICommonControlsTestHost")
        app.launchArguments = ["-attributed-text-view", "-label-role", "-custom-container"]
        app.launch()

        let combined = app.descendants(matching: .any)["composed"]
        XCTAssertTrue(combined.waitForExistence(timeout: 5))
        XCTAssertEqual(combined.label, "Terms Privacy")
        XCTAssertEqual(combined.value as? String, "42 dollars")
    }

    func test_togglingSelectionUpdatesGeneratedLinks() throws {
        try XCTSkipIf(ProcessInfo.processInfo.operatingSystemVersion.majorVersion < 17)
        let app = XCUIApplication(bundleIdentifier: "com.squareup.blueprint.BlueprintUICommonControlsTestHost")
        app.launchArguments = ["-attributed-text-view", "-detect-links"]
        app.launch()

        let detected = app.links.matching(NSPredicate(format: "label CONTAINS %@", "/detected")).firstMatch
        let toggle = app.buttons["Toggle selection"]
        XCTAssertTrue(detected.waitForExistence(timeout: 5))

        toggle.tap()
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: detected)
        XCTAssertEqual(XCTWaiter.wait(for: [gone], timeout: 5), .completed)
        XCTAssertTrue(app.links["Terms"].exists)

        toggle.tap()
        XCTAssertTrue(detected.waitForExistence(timeout: 5))
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
