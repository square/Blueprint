import AccessibilitySnapshot
import BlueprintUI
import BlueprintUICommonControls
import SnapshotTesting
import XCTest

/// Accessibility snapshot tests for Label control.
/// Tests various label configurations to ensure proper accessibility support.
class LabelAccessibilitySnapshotTests: XCTestCase {

    func test_label_basic() {
        let label = Label(text: "Basic Label")

        assertAccessibilitySnapshot(of: label)
    }

    func test_label_multiline() {
        let label = Label(text: "This is a longer label that spans multiple lines\nto test accessibility with wrapped text content.")


        assertAccessibilitySnapshot(of: label)
    }

}
