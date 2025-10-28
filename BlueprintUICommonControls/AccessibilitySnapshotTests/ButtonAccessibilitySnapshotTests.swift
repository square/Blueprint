import AccessibilitySnapshot
import BlueprintUI
import BlueprintUICommonControls
import SnapshotTesting
import XCTest

/// Accessibility snapshot tests for Button control.
/// Tests various button configurations to ensure proper accessibility support.
class ButtonAccessibilitySnapshotTests: XCTestCase {

    func test_button_basic() {
        let button = Button(wrapping: Label(text: "Basic Button"))

        assertAccessibilitySnapshot(of: button)
    }

    func test_button_with_icon_and_text() {
        let content = Row(minimumSpacing: 8) {
            Label(text: "📁")
            Label(text: "Open File")
        }

        let button = Button(wrapping: content)

        assertAccessibilitySnapshot(of: button)
    }

    func test_button_with_multipleText() {
        let content = Row(minimumSpacing: 8) {
            Label(text: "One")
            Label(text: "Two")
        }

        let button = Button(wrapping: content)

        assertAccessibilitySnapshot(of: button)
    }


    func test_button_multiline_text() {
        let button = Button(wrapping:
            Label(text: "This is a button with\nmultiple lines of text")
        )

        assertAccessibilitySnapshot(of: button)
    }
}
