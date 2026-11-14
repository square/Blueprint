import BlueprintUI
import Testing
import UIKit
@testable import BlueprintUICommonControls

@MainActor
struct AttributedTextViewTests {
    @Test func `Empty content measures zero after a nonempty update`() {
        guard #available(iOS 16.0, *) else { return }
        let view = AttributedTextView.View()
        view.update(.init(attributedText: NSAttributedString(string: "Body")))
        view.update(.init(attributedText: NSAttributedString(string: "")))
        #expect(view.sizeThatFits(CGSize(width: 200, height: CGFloat.infinity)) == .zero)
    }

    @Test func `Selection can be disabled without removing native links`() {
        guard #available(iOS 16.0, *) else { return }
        let url = URL(string: "https://example.com")!
        let model = AttributedTextView(attributedText: NSAttributedString(string: "Help", attributes: [.link: url])) {
            $0.isSelectable = false
        }
        let view = model.makeUIView()
        view.update(model)
        #expect(!view.textView.isSelectable)
        #expect(!view.textView.canPerformAction(#selector(UIResponderStandardEditActions.copy(_:)), withSender: nil))
        #expect(view.textView.attributedText.attribute(.link, at: 0, effectiveRange: nil) as? URL == url)
        if #available(iOS 17.0, *) {
            #expect(view.responds(to: #selector(UITextViewDelegate.textView(_:primaryActionFor:defaultAction:))))
        }
    }

    @Test func `Line limits constrain measured content`() {
        guard #available(iOS 16.0, *) else { return }
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
        #expect(full.height > 100)
        model.numberOfLines = 2
        view.update(model)
        #expect(view.sizeThatFits(size).height < full.height)
        model.numberOfLines = 0
        view.update(model)
        #expect(view.sizeThatFits(size) == full)
    }

    @Test func `Font fitting is shared by measurement and layout and resets`() throws {
        guard #available(iOS 16.0, *) else { return }
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
        let font = try #require(view.textView.attributedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)
        #expect(font.pointSize >= 20 && font.pointSize < 40)
        view.frame = CGRect(x: 0, y: 0, width: 200, height: measured.height)
        view.layoutIfNeeded()
        #expect(view.textView.attributedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont == font)
        model.adjustsFontSizeToFitWidth = false
        view.update(model)
        #expect((view.textView.attributedText.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)?.pointSize == 40)
    }

    @Test func `Reused views clear shadow and accessibility overrides`() {
        guard #available(iOS 16.0, *) else { return }
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
        let nativeTraits = view.textView.accessibilityTraits
        view.update(model)
        #expect(view.textView.accessibilityElementsHidden)
        #expect(view.textView.layer.shadowOpacity == 0.5)
        model = AttributedTextView(attributedText: NSAttributedString(string: "New body"))
        view.update(model)
        #expect(!view.textView.accessibilityElementsHidden)
        #expect(view.textView.accessibilityLabel == nil)
        #expect(view.textView.accessibilityValue == nil)
        #expect(view.textView.accessibilityHint == nil)
        #expect(view.textView.accessibilityIdentifier == nil)
        #expect(view.textView.accessibilityTraits == nativeTraits)
        #expect(view.textView.layer.shadowOpacity == 0)
        #expect(!view.textView.layer.shouldRasterize)
        #expect((view.textView.attributedText.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)?.allowsDefaultTighteningForTruncation == false)
    }

    @Test func `Native list attributes survive and the view remains in TextKit 2`() {
        guard #available(iOS 16.0, *) else { return }
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

        #expect(view.textView.textLayoutManager != nil)
        #expect(!view.textView.isEditable)
        #expect(view.textView.isSelectable)
        #expect(!view.textView.isScrollEnabled)
        #expect(view.textView.attributedText.isEqual(to: content))
    }

    @Test func `Reapplying unchanged content preserves the selection`() {
        guard #available(iOS 16.0, *) else { return }
        let model = AttributedTextView(attributedText: NSAttributedString(string: "Select these words"))
        let view = model.makeUIView()
        view.update(model)
        view.textView.selectedRange = NSRange(location: 7, length: 5)
        view.update(model)
        #expect(view.textView.selectedRange == NSRange(location: 7, length: 5))
    }

    @Test func `Wrapped content grows when the available width shrinks`() {
        guard #available(iOS 16.0, *) else { return }
        let model = AttributedTextView(attributedText: NSAttributedString(
            string: String(repeating: "A paragraph with enough words to wrap. ", count: 5),
            attributes: [.font: UIFont.preferredFont(forTextStyle: .body)]
        ))
        let view = model.makeUIView()
        view.update(model)
        let wide = view.sizeThatFits(CGSize(width: 300, height: CGFloat.greatestFiniteMagnitude))
        let narrow = view.sizeThatFits(CGSize(width: 150, height: CGFloat.greatestFiniteMagnitude))
        #expect(narrow.height > wide.height)
        #expect(narrow.width <= 150)
    }

    @Test func `Restyling unchanged characters preserves the selection`() {
        guard #available(iOS 16.0, *) else { return }
        let view = AttributedTextView.View()
        view.update(AttributedTextView(attributedText: NSAttributedString(
            string: "Select these words", attributes: [.font: UIFont.systemFont(ofSize: 17)]
        )))
        view.textView.selectedRange = NSRange(location: 7, length: 5)
        view.update(AttributedTextView(attributedText: NSAttributedString(
            string: "Select these words", attributes: [.font: UIFont.systemFont(ofSize: 30)]
        )))
        #expect(view.textView.selectedRange == NSRange(location: 7, length: 5))
    }

    @Test func `Link activation uses the supplied handler and leaves previews to UIKit`() {
        guard #available(iOS 16.0, *) else { return }
        let view = AttributedTextView.View()
        let model = AttributedTextView(attributedText: NSAttributedString(string: "Help"))
        let url = URL(string: "https://example.com/help")!
        var opened: [URL] = []
        view.update(model, onLinkTap: { opened.append($0) })
        let range = NSRange(location: 0, length: 4)
        #expect(!view.textView(view.textView, shouldInteractWith: url, in: range, interaction: .invokeDefaultAction))
        #expect(opened == [url])
        #expect(view.textView(view.textView, shouldInteractWith: url, in: range, interaction: .presentActions))
    }

    @Test func `Unconstrained measurement returns a finite content size`() {
        guard #available(iOS 16.0, *) else { return }
        let model = AttributedTextView(attributedText: NSAttributedString(
            string: "A short paragraph",
            attributes: [.font: UIFont.preferredFont(forTextStyle: .body)]
        ))
        let view = model.makeUIView()
        view.update(model)
        let size = view.sizeThatFits(CGSize(width: CGFloat.infinity, height: CGFloat.infinity))
        #expect(size.width.isFinite && size.width > 0)
        #expect(size.height.isFinite && size.height > 0)
    }

    @Test func `Text offset changes placement without changing measurement`() {
        guard #available(iOS 16.0, *) else { return }
        var model = AttributedTextView(attributedText: NSAttributedString(string: "Body text"))
        let view = model.makeUIView()
        view.update(model)
        let constraint = CGSize(width: 200, height: CGFloat.infinity)
        let size = view.sizeThatFits(constraint)
        view.frame.size = size
        model.textRectOffset = UIOffset(horizontal: 0, vertical: -4)
        view.update(model)
        view.layoutIfNeeded()
        #expect(view.textView.frame == view.bounds.offsetBy(dx: 0, dy: -4))
        #expect(view.sizeThatFits(constraint) == size)
    }
}
