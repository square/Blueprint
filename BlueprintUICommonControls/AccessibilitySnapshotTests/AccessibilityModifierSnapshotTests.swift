import AccessibilitySnapshot
import BlueprintUI
import BlueprintUICommonControls
import SnapshotTesting
import XCTest

/// Accessibility snapshot tests for accessibility modifier controls.
/// Tests various accessibility configurations to ensure proper accessibility support.
class AccessibilityModifierSnapshotTests: XCTestCase {

    func test_accessibility_element_basic() {
        let content = Label(text: "Basic Element")
            .accessibilityElement(
                label: "Custom Label",
                value: "Custom Value",
                traits: [.button]
            )

        assertAccessibilitySnapshot(of: content, record: true)
    }

    func test_accessibility_element_with_hint() {
        let content = Label(text: "Save Document")
            .accessibilityElement(
                label: "Save Document",
                value: nil,
                traits: [.button],
                hint: "Saves the current document to disk"
            )

        assertAccessibilitySnapshot(of: content)
    }

    func test_accessibility_hidden() {
        let content = Column(minimumSpacing: 8) {
            Label(text: "Visible Label")

            Label(text: "Hidden Decorative Element")
                .blockAccessibility()

            Label(text: "Another Visible Label")
        }

        assertAccessibilitySnapshot(of: content)
    }

    func test_accessibility_container() {
        let content = Column(minimumSpacing: 12) {
            Label(text: "Container ")

            Row(minimumSpacing: 8) {
                Label(text: "Item 1")
                Label(text: "Item 2")
                Label(text: "Item 3")
            }
            .accessibilityContainer(label: "Container Title")
        }

        assertAccessibilitySnapshot(of: content)
    }

    func test_accessibility_label_override() {
        let content = Column(minimumSpacing: 8) {
            Label(text: "42°F")
                .accessibilityElement(label: "42 degrees Fahrenheit", value: nil, traits: [])


            Label(text: "NASA")
                .accessibilityElement(label: "National Aeronautics and Space Administration", value: nil, traits: [])


            Label(text: "🎉")
                .accessibilityElement(label: "Celebration", value: nil, traits: [])

        }

        assertAccessibilitySnapshot(of: content)
    }

    func test_accessibility_value_override() {
        let content = Column(minimumSpacing: 8) {
            Label(text: "Progress: 75%")
                .accessibilityElement(label: "Progress", value: "75 percent complete", traits: [])

            Label(text: "Battery: 50%")
                .accessibilityElement(label: "Battery", value: "50 percent charged", traits: [])

        }

        assertAccessibilitySnapshot(of: content)
    }

    func test_accessibility_traits() {
        let content = Column(minimumSpacing: 12) {
            Label(text: "Header Text")
                .accessibilityElement(label: "Header Text", value: nil, traits: [.header])

            Label(text: "Button Text")
                .accessibilityElement(label: "Button Text", value: nil, traits: [.button])

            Label(text: "Back Button Text")
                .accessibilityElement(label: "Button Text", value: nil, traits: [.backButton])

            Label(text: "Toggle Text")
                .accessibilityElement(label: "Toggle Text", value: nil, traits: [.toggleButton])

            Label(text: "Link Text")
                .accessibilityElement(label: "Link Text", value: nil, traits: [.link])

            Label(text: "Selected Item")
                .accessibilityElement(label: "Selected Text", value: nil, traits: [.selected])

            Label(text: "Disabled Item")
                .accessibilityElement(label: "Disabled Text", value: nil, traits: [.notEnabled])
        }

        assertAccessibilitySnapshot(of: content)
    }

    func test_accessibility_complex_element() {
        let element =
            Column(minimumSpacing: 8) {
                Row(minimumSpacing: 8) {
                    Label(text: "👤")

                    Label(text: "John Doe")

                    Spacer()

                    Label(text: "Online")
                }

                Label(text: "Software Engineer at Tech Corp")

                Label(text: "Last seen 2 minutes ago")
            }
            .inset(uniform: 12)
            .accessibilityElement(
                label: "John Doe",
                value: "Software Engineer at Tech Corp, Online, Last seen 2 minutes ago",
                traits: [.button],
                hint: "Tap to view profile"
            )

        assertAccessibilitySnapshot(of: element)
    }
}
