import BlueprintUI
import UIKit
import XCTest
@testable import BlueprintUICommonControls

@MainActor
final class AttributedTextViewTests: XCTestCase {
    func test_wrapperExposesNativeAccessibilityChild() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("AttributedTextView requires iOS 17") }
        var model = AttributedTextView(attributedText: NSAttributedString(string: "First\nSecond")) {
            $0.isSelectable = false
        }
        let view = model.makeUIView()
        view.update(model)
        let children = try XCTUnwrap(view.accessibilityElements)
        XCTAssertEqual(children.count, 1)
        XCTAssertIdentical(children.first as? UITextView, view.textView)
        XCTAssertFalse(view.textView.isAccessibilityElement)
        XCTAssertFalse(view.textView.accessibilityElementsHidden)
        model.isAccessibilityElement = false
        view.update(model)
        XCTAssertEqual(view.accessibilityElements?.isEmpty, true)
        model.isAccessibilityElement = nil
        view.update(model)
        XCTAssertIdentical(view.accessibilityElements?.first as? UITextView, view.textView)
    }

    func test_detectedLinksPreserveExplicitLinksAndSelection() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("AttributedTextView requires iOS 17") }
        let text = NSMutableAttributedString(string: "https://example.com/original https://example.com/detected")
        let explicitRange = (text.string as NSString).range(of: "example.com/original")
        let detectedRange = (text.string as NSString).range(of: "https://example.com/detected")
        let explicitURL = URL(string: "https://example.com/override")!
        let detectedURL = URL(string: "https://example.com/detected")!
        text.addAttribute(.link, value: explicitURL, range: explicitRange)
        var model = AttributedTextView(attributedText: text)
        let view = model.makeUIView()
        view.update(model)
        let selection = NSRange(location: 0, length: 2)
        view.textView.selectedRange = selection

        model.linkDetectionTypes = [.link]
        view.update(model)
        XCTAssertEqual(
            view.textView.attributedText.attribute(.link, at: explicitRange.location, effectiveRange: nil) as? URL,
            explicitURL
        )
        XCTAssertEqual(
            view.textView.attributedText.attribute(.link, at: detectedRange.location, effectiveRange: nil) as? URL,
            detectedURL
        )
        XCTAssertEqual(view.textView.selectedRange, selection)

        model.isSelectable = false
        view.update(model)
        XCTAssertEqual(
            view.textView.attributedText.attribute(.link, at: detectedRange.location, effectiveRange: nil) as? URL,
            detectedURL
        )

        model.linkDetectionTypes = []
        view.update(model)
        XCTAssertNil(view.textView.attributedText.attribute(.link, at: detectedRange.location, effectiveRange: nil))
        XCTAssertEqual(
            view.textView.attributedText.attribute(.link, at: explicitRange.location, effectiveRange: nil) as? URL,
            explicitURL
        )
    }

    func test_emptyContentMeasuresZeroAfterUpdate() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("AttributedTextView requires iOS 17") }
        let view = AttributedTextView.View()
        view.update(.init(attributedText: NSAttributedString(string: "Body")))
        view.update(.init(attributedText: NSAttributedString(string: "")))
        XCTAssertEqual(view.sizeThatFits(CGSize(width: 200, height: CGFloat.infinity)), .zero)
    }

    func test_disablingSelectionKeepsExplicitLinksAndDisablesCopying() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("AttributedTextView requires iOS 17") }
        let url = URL(string: "https://example.com")!
        let model = AttributedTextView(attributedText: NSAttributedString(string: "Help", attributes: [.link: url])) {
            $0.isSelectable = false
        }
        let view = model.makeUIView()
        view.update(model)
        XCTAssertFalse(view.textView.isSelectable)
        XCTAssertFalse(view.textView.canPerformAction(
            #selector(UIResponderStandardEditActions.copy(_:)),
            withSender: nil
        ))
        XCTAssertEqual(view.textView.attributedText.attribute(.link, at: 0, effectiveRange: nil) as? URL, url)
    }

    func test_lineLimitConstrainsMeasuredHeight() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("AttributedTextView requires iOS 17") }
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail
        var model = AttributedTextView(attributedText: NSAttributedString(
            string: String(repeating: "A longer paragraph. ", count: 10),
            attributes: [.font: UIFont.systemFont(ofSize: 20), .paragraphStyle: paragraph]
        ))
        let view = model.makeUIView()
        view.update(model)
        let size = CGSize(width: 180, height: CGFloat.infinity)
        let full = view.sizeThatFits(size)
        XCTAssertTrue(full.height > 100)
        model.numberOfLines = 2
        view.update(model)
        XCTAssertTrue(view.sizeThatFits(size).height < full.height)
        model.numberOfLines = 0
        view.update(model)
        XCTAssertEqual(view.sizeThatFits(size), full)
    }

    func test_fontFittingMatchesMeasurementAndDisplayAndResets() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("AttributedTextView requires iOS 17") }
        var model = AttributedTextView(attributedText: NSAttributedString(
            string: "A long single line of text", attributes: [.font: UIFont.systemFont(ofSize: 40)]
        )) {
            $0.numberOfLines = 1
            $0.adjustsFontSizeToFitWidth = true
            $0.minimumScaleFactor = 0.5
        }
        let view = model.makeUIView()
        view.update(model)
        let measured = view.sizeThatFits(CGSize(width: 200, height: CGFloat.infinity))
        let font = try XCTUnwrap(view.textView.attributedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)
        XCTAssertTrue(font.pointSize >= 20 && font.pointSize < 40)
        view.frame = CGRect(x: 0, y: 0, width: 200, height: measured.height)
        view.layoutIfNeeded()
        XCTAssertEqual(view.textView.attributedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont, font)
        model.adjustsFontSizeToFitWidth = false
        view.update(model)
        XCTAssertEqual(
            (view.textView.attributedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)?.pointSize,
            40
        )
    }

    func test_measuringAtAnotherWidthKeepsDisplayedFontAfterLayout() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("AttributedTextView requires iOS 17") }
        let model = AttributedTextView(attributedText: NSAttributedString(
            string: "A longer sentence for font fitting",
            attributes: [.font: UIFont.systemFont(ofSize: 40)]
        )) {
            $0.numberOfLines = 1
            $0.adjustsFontSizeToFitWidth = true
            $0.minimumScaleFactor = 0.1
        }
        let view = model.makeUIView()
        view.frame = CGRect(x: 0, y: 0, width: 260, height: 50)
        view.update(model)
        view.layoutIfNeeded()
        let font = try XCTUnwrap(view.textView.attributedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)

        _ = view.sizeThatFits(CGSize(width: 120, height: CGFloat.infinity))
        view.layoutIfNeeded()

        XCTAssertEqual(view.textView.attributedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont, font)
    }

    func test_fontFittingKeepsTextWithinAvailableWidth() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("AttributedTextView requires iOS 17") }
        let model = AttributedTextView(attributedText: NSAttributedString(
            string: "Long single line of text that does not fit",
            attributes: [.font: UIFont.systemFont(ofSize: 40)]
        )) {
            $0.numberOfLines = 1
            $0.adjustsFontSizeToFitWidth = true
        }
        for width in [CGFloat(120), 220] {
            let view = model.makeUIView()
            view.update(model)
            _ = view.sizeThatFits(CGSize(width: width, height: .infinity))
            XCTAssertLessThanOrEqual(view.textView.attributedText.size().width, width)
            XCTAssertEqual(view.textView.text, model.attributedText.string)
        }
    }

    func test_reuseClearsShadowAndAccessibilityOverrides() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("AttributedTextView requires iOS 17") }
        var model = AttributedTextView(attributedText: NSAttributedString(string: "Body")) {
            $0.shadow = .init(radius: 2, opacity: 0.5, offset: .zero, color: .red)
            $0.accessibilityLabel = "Custom"
            $0.accessibilityValue = "Value"
            $0.accessibilityHint = "Hint"
            $0.accessibilityIdentifier = "Identifier"
            $0.accessibilityTraits = [.header]
            $0.isAccessibilityElement = false
            $0.allowsDefaultTighteningForTruncation = true
        }
        let view = model.makeUIView()
        view.update(model)
        XCTAssertTrue(view.textView.accessibilityElementsHidden)
        XCTAssertEqual(view.textView.layer.shadowOpacity, 0.5)
        model.isAccessibilityElement = true
        view.update(model)
        XCTAssertTrue(view.textView.isAccessibilityElement)
        model = AttributedTextView(attributedText: NSAttributedString(string: "New body"))
        view.update(model)
        let fresh = model.makeUIView()
        fresh.update(model)
        XCTAssertFalse(view.textView.accessibilityElementsHidden)
        XCTAssertEqual(view.textView.isAccessibilityElement, fresh.textView.isAccessibilityElement)
        XCTAssertNil(view.textView.accessibilityLabel)
        XCTAssertNil(view.textView.accessibilityValue)
        XCTAssertNil(view.textView.accessibilityHint)
        XCTAssertNil(view.textView.accessibilityIdentifier)
        XCTAssertEqual(view.textView.accessibilityTraits, fresh.textView.accessibilityTraits)
        XCTAssertEqual(view.textView.layer.shadowOpacity, 0)
        XCTAssertFalse(view.textView.layer.shouldRasterize)
        XCTAssertEqual(
            (view.textView.attributedText.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)?.allowsDefaultTighteningForTruncation,
            false
        )
    }

    func test_accessibilityRolesPreserveOverridesAndClearThemOnReuse() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("AttributedTextView requires iOS 17") }
        let view = AttributedTextView.View()
        let label = NSAttributedString(string: "Label override", attributes: [.accessibilitySpeechLanguage: "fr-FR"])
        let value = NSAttributedString(string: "Value override", attributes: [.accessibilitySpeechLanguage: "en-US"])
        let hint = NSAttributedString(string: "Hint override", attributes: [.accessibilitySpeechLanguage: "fr-FR"])
        for role in [AttributedTextView.TextAccessibilityRole.label, .value, .hint] {
            var model = AttributedTextView(attributedText: NSAttributedString(string: "Body")) {
                $0.textAccessibilityRole = role
                $0.accessibilityAttributedLabel = label
                $0.accessibilityAttributedValue = value
                $0.accessibilityAttributedHint = hint
            }
            view.update(model)
            XCTAssertEqual(view.textView.accessibilityAttributedLabel, label)
            XCTAssertEqual(view.textView.accessibilityAttributedValue, value)
            XCTAssertEqual(view.textView.accessibilityAttributedHint, hint)
            model.accessibilityLabel = nil
            model.accessibilityValue = nil
            model.accessibilityHint = nil
            view.update(model)
            XCTAssertNotEqual(view.textView.accessibilityLabel, "Label override")
            XCTAssertNotEqual(view.textView.accessibilityValue, "Value override")
            XCTAssertNotEqual(view.textView.accessibilityHint, "Hint override")
        }
    }

    func test_listAttributesRemainInTextKit2() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("AttributedTextView requires iOS 17") }
        let list = NSTextList(markerFormat: .decimal, options: 0)
        list.startingItemNumber = 9
        let paragraph = NSMutableParagraphStyle()
        paragraph.textLists = [list]
        let content = NSAttributedString(string: "Nine\nTen", attributes: [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .paragraphStyle: paragraph,
        ])
        let model = AttributedTextView(attributedText: content)
        let view = model.makeUIView()
        view.update(model)

        XCTAssertNotNil(view.textView.textLayoutManager)
        XCTAssertFalse(view.textView.isEditable)
        XCTAssertTrue(view.textView.isSelectable)
        XCTAssertFalse(view.textView.isScrollEnabled)
        XCTAssertTrue(view.textView.attributedText.isEqual(to: content))
    }

    func test_unchangedContentPreservesSelection() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("AttributedTextView requires iOS 17") }
        let model = AttributedTextView(attributedText: NSAttributedString(string: "Select these words"))
        let view = model.makeUIView()
        view.update(model)
        view.textView.selectedRange = NSRange(location: 7, length: 5)
        view.update(model)
        XCTAssertEqual(view.textView.selectedRange, NSRange(location: 7, length: 5))
    }

    func test_wrappedContentGrowsAtNarrowerWidth() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("AttributedTextView requires iOS 17") }
        let model = AttributedTextView(attributedText: NSAttributedString(
            string: String(repeating: "A paragraph with enough words to wrap. ", count: 5),
            attributes: [.font: UIFont.preferredFont(forTextStyle: .body)]
        ))
        let view = model.makeUIView()
        view.update(model)
        let wide = view.sizeThatFits(CGSize(width: 300, height: CGFloat.greatestFiniteMagnitude))
        let narrow = view.sizeThatFits(CGSize(width: 150, height: CGFloat.greatestFiniteMagnitude))
        XCTAssertTrue(narrow.height > wide.height)
        XCTAssertTrue(narrow.width <= 150)
    }

    func test_restylingUnchangedContentPreservesSelection() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("AttributedTextView requires iOS 17") }
        let view = AttributedTextView.View()
        view.update(AttributedTextView(attributedText: NSAttributedString(
            string: "Select these words", attributes: [.font: UIFont.systemFont(ofSize: 17)]
        )))
        view.textView.selectedRange = NSRange(location: 7, length: 5)
        view.update(AttributedTextView(attributedText: NSAttributedString(
            string: "Select these words", attributes: [.font: UIFont.systemFont(ofSize: 30)]
        )))
        XCTAssertEqual(view.textView.selectedRange, NSRange(location: 7, length: 5))
    }

    func test_unconstrainedMeasurementReturnsFiniteSize() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("AttributedTextView requires iOS 17") }
        let model = AttributedTextView(attributedText: NSAttributedString(
            string: "A short paragraph",
            attributes: [.font: UIFont.preferredFont(forTextStyle: .body)]
        ))
        let view = model.makeUIView()
        view.update(model)
        let size = view.sizeThatFits(CGSize(width: CGFloat.infinity, height: CGFloat.infinity))
        XCTAssertTrue(size.width.isFinite && size.width > 0)
        XCTAssertTrue(size.height.isFinite && size.height > 0)
    }

    func test_textOffsetChangesPlacementWithoutChangingMeasurement() throws {
        guard #available(iOS 17.0, *) else { throw XCTSkip("AttributedTextView requires iOS 17") }
        var model = AttributedTextView(attributedText: NSAttributedString(string: "Body text"))
        let view = model.makeUIView()
        view.update(model)
        let constraint = CGSize(width: 200, height: CGFloat.infinity)
        let size = view.sizeThatFits(constraint)
        view.frame.size = size
        model.textRectOffset = UIOffset(horizontal: 0, vertical: -4)
        view.update(model)
        view.layoutIfNeeded()
        XCTAssertEqual(view.textView.frame, view.bounds.offsetBy(dx: 0, dy: -4))
        XCTAssertEqual(view.sizeThatFits(constraint), size)
    }
}
