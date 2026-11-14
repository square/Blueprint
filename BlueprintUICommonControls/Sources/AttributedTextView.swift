import BlueprintUI
import UIKit

/// Displays read-only attributed text using TextKit 2 and native text accessibility.
/// The view grows to fit its content; place it in a scroll view for long documents.
@available(iOS 17.0, *)
public struct AttributedTextView: UIViewElement {
    public var attributedText: NSAttributedString
    public var isSelectable = true
    public var numberOfLines = 0
    public var shadow: TextShadow?
    public var adjustsFontSizeToFitWidth = false
    public var minimumScaleFactor: CGFloat = 0
    public var allowsDefaultTighteningForTruncation = false

    /// Attributes UIKit applies to links, in addition to the attributed text's styling.
    public var linkAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.link]

    /// Offsets the rendered text without changing its measured size.
    public var textRectOffset: UIOffset = .zero

    /// Defaults to UIKit's native paragraph accessibility; set `true` to expose one element.
    public var isAccessibilityElement: Bool?
    public var accessibilityTraits: Set<AccessibilityElement.Trait>?
    public var accessibilityLabel: String?
    public var accessibilityValue: String?
    public var accessibilityHint: String?
    public var accessibilityIdentifier: String?
    public var accessibilityCustomActions: [AccessibilityElement.CustomAction] = []

    public init(attributedText: NSAttributedString, configure: (inout Self) -> Void = { _ in }) {
        self.attributedText = attributedText
        configure(&self)
    }

    public func makeUIView() -> View { View() }

    public func updateUIView(_ view: View, with context: UIViewElementContext) {
        view.update(self, onLinkTap: context.isMeasuring ? nil : context.environment.urlHandler.onTap)
        if context.isMeasuring { view.textView.accessibilityCustomActions = nil }
    }

    /// The shared UIKit implementation, also suitable for hosting outside Blueprint.
    public final class View: UIView, UITextViewDelegate {
        let textView = UITextView(usingTextLayoutManager: true)
        private var onLinkTap: ((URL) -> Void)?
        private var textRectOffset: UIOffset = .zero
        private var sourceText = NSAttributedString(string: "")
        private var adjustsFontSizeToFitWidth = false
        private var minimumScaleFactor: CGFloat = 0
        private var fittingWidth: CGFloat?
        private var nativeTraits: UIAccessibilityTraits = []
        private var nativeIsAccessibilityElement = false

        public init() {
            super.init(frame: .zero)
            textView.isEditable = false
            textView.isScrollEnabled = false
            textView.backgroundColor = .clear
            textView.textContainerInset = .zero
            textView.textContainer.lineFragmentPadding = 0
            textView.delegate = self
            nativeTraits = textView.accessibilityTraits
            nativeIsAccessibilityElement = textView.isAccessibilityElement
            addSubview(textView)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        public func update(_ model: AttributedTextView, onLinkTap: ((URL) -> Void)? = nil) {
            self.onLinkTap = onLinkTap
            textRectOffset = model.textRectOffset
            adjustsFontSizeToFitWidth = model.adjustsFontSizeToFitWidth
            minimumScaleFactor = model.minimumScaleFactor
            textView.isSelectable = model.isSelectable
            textView.linkTextAttributes = model.linkAttributes
            textView.textContainer.maximumNumberOfLines = max(0, model.numberOfLines)
            let lastLineMode = model.attributedText.length > 0
                ? (model.attributedText.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)?.lineBreakMode ?? .byWordWrapping
                : .byWordWrapping
            textView.textContainer.lineBreakMode = lastLineMode.normalized(forNumberOfLines: model.numberOfLines)

            let text = NSMutableAttributedString(attributedString: model.attributedText)
            text.enumerateAttributes(in: NSRange(location: 0, length: text.length)) { attributes, range, _ in
                let paragraph = (attributes[.paragraphStyle] as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
                paragraph.lineBreakMode = paragraph.lineBreakMode.normalized(forNumberOfLines: model.numberOfLines)
                // UITextView otherwise truncates every paragraph, even with unlimited lines.
                if model.numberOfLines != 1 && paragraph.lineBreakMode == .byTruncatingTail {
                    paragraph.lineBreakMode = .byWordWrapping
                }
                paragraph.allowsDefaultTighteningForTruncation = model.allowsDefaultTighteningForTruncation
                text.addAttribute(.paragraphStyle, value: paragraph, range: range)
                if attributes[.font] == nil {
                    text.addAttribute(.font, value: UIFont.systemFont(ofSize: UIFont.labelFontSize), range: range)
                }
            }
            sourceText = text
            fittingWidth = nil
            applyText(fitting: bounds.width)

            textView.isAccessibilityElement = model.isAccessibilityElement ?? nativeIsAccessibilityElement
            textView.accessibilityElementsHidden = model.isAccessibilityElement == false
            textView.accessibilityTraits = model.accessibilityTraits.map(UIAccessibilityTraits.init(with:)) ?? nativeTraits
            textView.accessibilityLabel = model.accessibilityLabel
            textView.accessibilityValue = model.accessibilityValue
            textView.accessibilityHint = model.accessibilityHint
            textView.accessibilityIdentifier = model.accessibilityIdentifier
            textView.accessibilityCustomActions = model.accessibilityCustomActions.map { action in
                UIAccessibilityCustomAction(name: action.name) { _ in action.onActivation() }
            }
            textView.layer.shadowOpacity = Float(model.shadow?.opacity ?? 0)
            textView.layer.shadowRadius = model.shadow?.radius ?? 0
            textView.layer.shadowOffset = model.shadow.map { CGSize(width: $0.offset.horizontal, height: $0.offset.vertical) } ?? .zero
            textView.layer.shadowColor = model.shadow?.color.cgColor
            textView.layer.shouldRasterize = model.shadow != nil
            textView.layer.rasterizationScale = textView.layer.contentsScale
            setNeedsLayout()
        }

        private func applyText(fitting width: CGFloat) {
            guard fittingWidth != width else { return }
            fittingWidth = width
            var text = sourceText
            if adjustsFontSizeToFitWidth, textView.textContainer.maximumNumberOfLines == 1,
               width > 0, width.isFinite, minimumScaleFactor < 1, sourceText.size().width > width {
                func scaledText(at scale: CGFloat) -> NSAttributedString {
                    let scaled = NSMutableAttributedString(attributedString: sourceText)
                    scaled.enumerateAttribute(.font, in: NSRange(location: 0, length: scaled.length)) { value, range, _ in
                        if let font = value as? UIFont {
                            scaled.addAttribute(.font, value: font.withSize(font.pointSize * scale), range: range)
                        }
                    }
                    return scaled
                }

                let minimum = max(0, min(1, minimumScaleFactor))
                var lower = minimum
                var upper: CGFloat = 1
                var fitted: NSAttributedString?
                // Font metrics change with point size, so measure candidates instead of scaling widths.
                for _ in 0..<12 {
                    let scale = (lower + upper) / 2
                    let candidate = scaledText(at: scale)
                    if candidate.size().width <= width {
                        fitted = candidate
                        lower = scale
                    } else {
                        upper = scale
                    }
                }
                text = fitted ?? scaledText(at: minimum > 0 ? minimum : upper)
            }
            guard !textView.attributedText.isEqual(to: text) else { return }
            let selection = textView.selectedRange
            let sameCharacters = textView.attributedText.string == text.string
            textView.attributedText = text
            if textView.isSelectable && sameCharacters { textView.selectedRange = selection }
        }

        public override func layoutSubviews() {
            super.layoutSubviews()
            applyText(fitting: bounds.width)
            textView.frame = bounds.offsetBy(dx: textRectOffset.horizontal, dy: textRectOffset.vertical)
        }

        public override func sizeThatFits(_ size: CGSize) -> CGSize {
            guard sourceText.length > 0 else { return .zero }
            applyText(fitting: size.width)
            return textView.sizeThatFits(size)
        }

        public func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
            guard case .link(let url) = textItem.content, onLinkTap != nil else { return defaultAction }
            return UIAction { [weak self] _ in self?.onLinkTap?(url) }
        }

        public func textView(_ textView: UITextView, menuConfigurationFor textItem: UITextItem, defaultMenu: UIMenu) -> UITextItem.MenuConfiguration? {
            .init(menu: defaultMenu)
        }
    }
}
