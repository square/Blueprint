import AccessibilitySnapshot
import BlueprintUI
import BlueprintUICommonControls
import SnapshotTesting
import XCTest

/// Accessibility snapshot tests for SegmentedControl control.
/// Tests various segmented control configurations to ensure proper accessibility support.
class SegmentedControlAccessibilitySnapshotTests: XCTestCase {

    func test_segmented_control_selected() {
        var segmentedControl = SegmentedControl()
        segmentedControl.appendItem(title: "First", onSelect: {})
        segmentedControl.appendItem(title: "Second", onSelect: {})
        segmentedControl.appendItem(title: "Third", onSelect: {})
        segmentedControl.selection = .index(1)

        assertAccessibilitySnapshot(of: segmentedControl)
    }


    func test_segmented_control_no_selection() {
        var segmentedControl = SegmentedControl()
        segmentedControl.appendItem(title: "Option A", onSelect: {})
        segmentedControl.appendItem(title: "Option B", onSelect: {})
        segmentedControl.appendItem(title: "Option C", onSelect: {})
        segmentedControl.selection = .none

        assertAccessibilitySnapshot(of: segmentedControl)
    }
}
