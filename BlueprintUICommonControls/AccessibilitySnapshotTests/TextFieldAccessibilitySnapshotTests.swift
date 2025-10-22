import AccessibilitySnapshot
import BlueprintUI
import BlueprintUICommonControls
import SnapshotTesting
import XCTest

/// Accessibility snapshot tests for TextField control.
/// Tests various text field configurations to ensure proper accessibility support.
class TextFieldAccessibilitySnapshotTests: XCTestCase {

    func test_textfield_empty() {
        let textField = TextField(text: "")
            .constrainedTo(width: 200, height: 44)

        assertAccessibilitySnapshot(of: textField)
    }

    func test_textfield_with_placeholder() {
        let textField = TextField(text: "") {
            $0.placeholder = "Enter your name"
        }
        .constrainedTo(width: 200, height: 44)

        assertAccessibilitySnapshot(of: textField)
    }

    func test_textfield_with_text() {
        let textField = TextField(text: "John Doe")
            .constrainedTo(width: 200, height: 44)

        assertAccessibilitySnapshot(of: textField)
    }

    func test_textfield_secure() {
        let textField = TextField(text: "password") {
            $0.secure = true
        }
        .constrainedTo(width: 200, height: 44)

        assertAccessibilitySnapshot(of: textField)
    }

    func test_textfield_disabled() {
        let textField = TextField(text: "Read only text") {
            $0.isEnabled = false
        }
        .constrainedTo(width: 200, height: 44)

        assertAccessibilitySnapshot(of: textField)
    }

}
