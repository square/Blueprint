import AccessibilitySnapshot
import BlueprintUI
import BlueprintUICommonControls
import SnapshotTesting
import XCTest

/// Accessibility snapshot tests for ScrollView control.
/// Tests various scroll view configurations to ensure proper accessibility support.
class ScrollViewAccessibilitySnapshotTests: XCTestCase {

    func test_scrollview_vertical() {
        let content = Column(minimumSpacing: 16) {
            Box(
                backgroundColor: .systemBlue,
                cornerStyle: .rounded(radius: 8),
                wrapping:
                Label(text: "Item 1").inset(uniform: 16)
            )
            Box(
                backgroundColor: .systemBlue,
                cornerStyle: .rounded(radius: 8),
                wrapping:
                Label(text: "Item 2").inset(uniform: 16)
            )
            Box(
                backgroundColor: .systemBlue,
                cornerStyle: .rounded(radius: 8),
                wrapping:
                Label(text: "Item 3").inset(uniform: 16)
            )
        }
        .inset(uniform: 16)

        let scrollView = ScrollView(.fittingHeight, wrapping: content)
            .constrainedTo(height: .absolute(200))
            .accessibilityElement(
                label: "Scrollable list",
                value: nil,
                traits: [],
                hint: "Swipe up or down to scroll"
            )

        assertAccessibilitySnapshot(of: scrollView)
    }

    func test_scrollview_horizontal() {
        let content = Row(minimumSpacing: 16) {
            Box(
                backgroundColor: .systemGreen,
                cornerStyle: .rounded(radius: 8),
                wrapping:
                Label(text: "Card 1").inset(uniform: 16)
            )
            Box(
                backgroundColor: .systemGreen,
                cornerStyle: .rounded(radius: 8),
                wrapping:
                Label(text: "Card 2").inset(uniform: 16)
            )
            Box(
                backgroundColor: .systemGreen,
                cornerStyle: .rounded(radius: 8),
                wrapping:
                Label(text: "Card 3").inset(uniform: 16)
            )
        }
        .inset(uniform: 16)

        let scrollView = ScrollView(.fittingWidth, wrapping: content)
            .constrainedTo(width: .absolute(300))
            .accessibilityElement(
                label: "Horizontal card list",
                value: nil,
                traits: [],
                hint: "Swipe left or right to scroll"
            )

        assertAccessibilitySnapshot(of: scrollView)
    }

    func test_scrollview_with_content_description() {
        let content = Column(minimumSpacing: 12) {
            Label(text: "Article Title")
                .accessibilityElement(label: nil, value: nil, traits: [.header])

            Label(text: "This is a long article with multiple paragraphs of content that requires scrolling to read completely.")

            Label(text: "Second paragraph with more detailed information about the topic being discussed.")

            Label(text: "Final paragraph concluding the article content.")
        }
        .inset(uniform: 16)

        let scrollView = ScrollView(.fittingHeight, wrapping: content)
            .constrainedTo(height: .absolute(150))
            .accessibilityElement(
                label: "Article content",
                value: nil,
                traits: [],
                hint: "Scroll to read full article"
            )

        assertAccessibilitySnapshot(of: scrollView)
    }

    func test_scrollview_empty() {
        let content = Column(minimumSpacing: 16) {
            Label(text: "No items to display")
                .accessibilityElement(label: "No items available", value: nil, traits: [.staticText])
        }
        .inset(uniform: 16)

        let scrollView = ScrollView(.fittingHeight, wrapping: content)
            .constrainedTo(height: .absolute(200))

        assertAccessibilitySnapshot(of: scrollView)
    }

    func test_scrollview_nested() {
        let innerContent = Row(minimumSpacing: 12) {
            Box(
                backgroundColor: .systemOrange,
                cornerStyle: .rounded(radius: 6),
                wrapping:
                Label(text: "1").inset(uniform: 12)
            )
            Box(
                backgroundColor: .systemOrange,
                cornerStyle: .rounded(radius: 6),
                wrapping:
                Label(text: "2").inset(uniform: 12)
            )
            Box(
                backgroundColor: .systemOrange,
                cornerStyle: .rounded(radius: 6),
                wrapping:
                Label(text: "3").inset(uniform: 12)
            )
        }
        .inset(horizontal: 16)

        let innerScrollView = ScrollView(.fittingWidth, wrapping: innerContent)
            .constrainedTo(height: .absolute(50))
            .accessibilityElement(
                label: "Horizontal items",
                value: nil,
                traits: [],
                hint: "Swipe horizontally to see more items"
            )

        let outerContent = Column(minimumSpacing: 20) {
            Label(text: "Outer Scroll Content")
                .accessibilityElement(label: nil, value: nil, traits: [.header])

            innerScrollView

            Label(text: "More outer content below")
        }
        .inset(uniform: 16)

        let outerScrollView = ScrollView(.fittingHeight, wrapping: outerContent)
            .constrainedTo(height: .absolute(200))

        assertAccessibilitySnapshot(of: outerScrollView)
    }

    func test_scrollview_fitting_content() {
        let content = Column(minimumSpacing: 8) {
            Label(text: "Short Content")
            Label(text: "That fits entirely")
        }
        .inset(uniform: 16)

        let scrollView = ScrollView(.fittingContent, wrapping: content)
            .accessibilityElement(
                label: "Non-scrollable content",
                value: nil,
                traits: [.staticText]
            )

        assertAccessibilitySnapshot(of: scrollView)
    }
}
