import BlueprintUI
import UIKit

/// Displays selectable, read-only attributed text using TextKit 2.
///
/// Paragraph styles, including `NSTextList` membership, are passed directly to UIKit.
/// The view grows to fit its content; place it in a scroll view for long documents.
@available(iOS 16.0, *)
public struct AttributedTextView: UIViewElement {
    public var attributedText: NSAttributedString

    /// Attributes UIKit applies to links, in addition to the attributed text's styling.
    public var linkAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.link]

    public init(attributedText: NSAttributedString, configure: (inout Self) -> Void = { _ in }) {
        self.attributedText = attributedText
        configure(&self)
    }

    public func makeUIView() -> View {
        View()
    }

    public func updateUIView(_ view: View, with context: UIViewElementContext) {
        view.update(self, onLinkTap: context.environment.urlHandler.onTap)
    }

    /// The shared UIKit implementation, also suitable for hosting outside Blueprint.
    public final class View: UIView, UITextViewDelegate {
        let textView = UITextView(usingTextLayoutManager: true)
        private var onLinkTap: ((URL) -> Void)?

        public init() {
            super.init(frame: .zero)
            textView.isEditable = false
            textView.isSelectable = true
            textView.isScrollEnabled = false
            textView.backgroundColor = .clear
            textView.textContainerInset = .zero
            textView.textContainer.lineFragmentPadding = 0
            textView.delegate = self
            addSubview(textView)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        /// Applies content and link routing without resetting selection for unchanged text.
        public func update(_ model: AttributedTextView, onLinkTap: ((URL) -> Void)? = nil) {
            self.onLinkTap = onLinkTap
            textView.linkTextAttributes = model.linkAttributes
            if !textView.attributedText.isEqual(to: model.attributedText) {
                textView.attributedText = model.attributedText
            }
        }

        public override func layoutSubviews() {
            super.layoutSubviews()
            textView.frame = bounds
        }

        public override func sizeThatFits(_ size: CGSize) -> CGSize {
            textView.sizeThatFits(size)
        }

        public func textView(
            _ textView: UITextView,
            shouldInteractWith url: URL,
            in characterRange: NSRange,
            interaction: UITextItemInteraction
        ) -> Bool {
            guard interaction == .invokeDefaultAction, let onLinkTap else { return true }
            onLinkTap(url)
            return false
        }
    }
}

