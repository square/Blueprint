import AccessibilitySnapshot
import BlueprintUI
import BlueprintUICommonControls
import SnapshotTesting
import XCTest

/// Accessibility snapshot tests for AttributedLabel control.
/// Tests various attributed label configurations to ensure proper accessibility support.
class AttributedLabelAccessibilitySnapshotTests: XCTestCase {

    func test_attributed_label_basic() {
        let attributedText = NSAttributedString(
            string: "Basic attributed text",
            attributes: [.foregroundColor: UIColor.label]
        )

        let label = AttributedLabel(attributedText: attributedText)

        assertAccessibilitySnapshot(of: label)
    }


    func test_attributed_label_with_links() {
        let attributedText = NSMutableAttributedString(string: "Visit our website at example.com for more information.")

        attributedText.addAttributes([
            .link: NSURL(string: "https://example.com")!,
        ], range: attributedText.mutableString.range(of: "example.com"))

        let label = AttributedLabel(attributedText: attributedText)
        assertAccessibilitySnapshot(of: label)
    }

    func test_attributed_label_multiline() {
        let attributedText = NSMutableAttributedString()

        attributedText.append(NSAttributedString(
            string: "First Line\n",
            attributes: [.font: UIFont.boldSystemFont(ofSize: 18)]
        ))

        attributedText.append(NSAttributedString(
            string: "Second line with regular text\n",
            attributes: [.font: UIFont.systemFont(ofSize: 16)]
        ))

        attributedText.append(NSAttributedString(
            string: "Third line in italic",
            attributes: [.font: UIFont.italicSystemFont(ofSize: 14)]
        ))

        let label = AttributedLabel(attributedText: attributedText)

        assertAccessibilitySnapshot(of: label)
    }

    func test_attributed_label_with_mixed_content() {
        let attributedText = NSMutableAttributedString()

        // Title
        attributedText.append(NSAttributedString(
            string: "Product Review\n",
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: 20),
                .foregroundColor: UIColor.label,
            ]
        ))

        // Rating
        attributedText.append(NSAttributedString(
            string: "⭐⭐⭐⭐⭐ ",
            attributes: [.font: UIFont.systemFont(ofSize: 16)]
        ))

        // Score
        attributedText.append(NSAttributedString(
            string: "5.0/5.0\n",
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.systemGreen,
            ]
        ))

        // Description
        attributedText.append(NSAttributedString(
            string: "Excellent product with great quality and fast shipping.",
            attributes: [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.secondaryLabel,
            ]
        ))

        let label = AttributedLabel(attributedText: attributedText)


        assertAccessibilitySnapshot(of: label)
    }

    func test_attributed_label_with_strikethrough() {
        let attributedText = NSMutableAttributedString()

        attributedText.append(NSAttributedString(
            string: "Original Price: ",
            attributes: [.font: UIFont.systemFont(ofSize: 16)]
        ))

        attributedText.append(NSAttributedString(
            string: "$29.99",
            attributes: [
                .font: UIFont.systemFont(ofSize: 16),
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: UIColor.secondaryLabel,
            ]
        ))

        attributedText.append(NSAttributedString(
            string: " Sale Price: ",
            attributes: [.font: UIFont.systemFont(ofSize: 16)]
        ))

        attributedText.append(NSAttributedString(
            string: "$19.99",
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: 16),
                .foregroundColor: UIColor.systemRed,
            ]
        ))

        let label = AttributedLabel(attributedText: attributedText)

        assertAccessibilitySnapshot(of: label)
    }
}
