import BlueprintUI
import Testing
import UIKit
@testable import BlueprintUICommonControls

@MainActor
struct AttributedTextViewTests {
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
}
