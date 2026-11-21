import BlueprintUI
import BlueprintUIAccessibilityCore
import UIKit

/// Displays read-only attributed text using TextKit 2 and native text accessibility.
/// The view grows to fit its content; place it in a scroll view for long documents.
@available(iOS 17.0, *)
public struct AttributedTextView: UIViewElement {
    public var attributedText: NSAttributedString
    public var isSelectable = true
    /// Data to detect and display as links. Detection is disabled by default.
    public var linkDetectionTypes: Set<TextLinkDetectionType> = []
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
    /// The accessibility property that receives the text when Blueprint combines the view with other content.
    /// Defaults to UIKit's label and value placement.
    public var textAccessibilityRole: TextAccessibilityRole?

    public enum TextAccessibilityRole: Equatable {
        case label, value, hint
    }

    /// Additional traits, merged with UIKit's native text and link traits.
    public var accessibilityTraits: Set<AccessibilityElement.Trait>?
    public var accessibilityAttributedLabel: NSAttributedString?
    public var accessibilityAttributedValue: NSAttributedString?
    public var accessibilityAttributedHint: NSAttributedString?

    public var accessibilityLabel: String? {
        get { accessibilityAttributedLabel?.string }
        set {
            if let newValue {
                accessibilityAttributedLabel = .init(string: newValue)
            } else {
                accessibilityAttributedLabel = nil
            }
        }
    }

    public var accessibilityValue: String? {
        get { accessibilityAttributedValue?.string }
        set {
            if let newValue {
                accessibilityAttributedValue = .init(string: newValue)
            } else {
                accessibilityAttributedValue = nil
            }
        }
    }

    public var accessibilityHint: String? {
        get { accessibilityAttributedHint?.string }
        set {
            if let newValue {
                accessibilityAttributedHint = .init(string: newValue)
            } else {
                accessibilityAttributedHint = nil
            }
        }
    }

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

    final class TextView: UITextView, AccessibilityCompositionTextProvider {
        var textAccessibilityRole: TextAccessibilityRole?
        var accessibilityElementOverride: Bool?
        var additionalAccessibilityTraits: UIAccessibilityTraits = []

        override var isAccessibilityElement: Bool {
            get { accessibilityElementOverride ?? super.isAccessibilityElement }
            set { super.isAccessibilityElement = newValue }
        }

        override var accessibilityTraits: UIAccessibilityTraits {
            get { super.accessibilityTraits.union(additionalAccessibilityTraits) }
            set { super.accessibilityTraits = newValue }
        }

        private var labelOverride: NSAttributedString?
        private var valueOverride: NSAttributedString?
        private var hintOverride: NSAttributedString?
        private var readingNativeAccessibility = false

        private func nativeText(for role: TextAccessibilityRole) -> NSAttributedString? {
            // UIKit's attributed getters can call its String getters.
            readingNativeAccessibility = true
            defer { readingNativeAccessibility = false }
            switch role {
            case .label: return super.accessibilityAttributedLabel ?? super.accessibilityLabel.map { .init(string: $0) }
            case .value: return super.accessibilityAttributedValue ?? super.accessibilityValue.map { .init(string: $0) }
            case .hint: return super.accessibilityAttributedHint ?? super.accessibilityHint.map { .init(string: $0) }
            }
        }

        private var nativeContent: NSAttributedString? {
            nativeText(for: .value) ?? nativeText(for: .label)
        }

        override var accessibilityAttributedLabel: NSAttributedString? {
            get {
                if readingNativeAccessibility { return super.accessibilityAttributedLabel }
                if let labelOverride { return labelOverride }
                return valueOverride != nil && textAccessibilityRole == .label ? nativeContent : nativeText(for: .label)
            }
            set { labelOverride = newValue }
        }

        override var accessibilityAttributedValue: NSAttributedString? {
            get {
                if readingNativeAccessibility { return super.accessibilityAttributedValue }
                return valueOverride ?? nativeText(for: .value)
            }
            set { valueOverride = newValue }
        }

        override var accessibilityAttributedHint: NSAttributedString? {
            get {
                if readingNativeAccessibility { return super.accessibilityAttributedHint }
                return hintOverride ?? nativeText(for: .hint)
            }
            set { hintOverride = newValue }
        }

        func attributedAccessibilityTextForComposition() -> (
            label: NSAttributedString?,
            value: NSAttributedString?,
            hint: NSAttributedString?
        ) {
            guard let textAccessibilityRole else {
                return (accessibilityAttributedLabel, accessibilityAttributedValue, accessibilityAttributedHint)
            }
            let content = nativeContent
            return (
                labelOverride ?? (textAccessibilityRole == .label ? content : nil),
                valueOverride ?? (textAccessibilityRole == .value ? content : nil),
                hintOverride ?? (textAccessibilityRole == .hint ? content : nativeText(for: .hint))
            )
        }

        override var accessibilityLabel: String? {
            get { readingNativeAccessibility ? super.accessibilityLabel : accessibilityAttributedLabel?.string }
            set { accessibilityAttributedLabel = newValue.map { .init(string: $0) } }
        }

        override var accessibilityValue: String? {
            get { readingNativeAccessibility ? super.accessibilityValue : accessibilityAttributedValue?.string }
            set { accessibilityAttributedValue = newValue.map { .init(string: $0) } }
        }

        override var accessibilityHint: String? {
            get { readingNativeAccessibility ? super.accessibilityHint : accessibilityAttributedHint?.string }
            set { accessibilityAttributedHint = newValue.map { .init(string: $0) } }
        }
    }

    /// The shared UIKit implementation, also suitable for hosting outside Blueprint.
    public final class View: UIView, UITextViewDelegate {
        let textView = TextView(usingTextLayoutManager: true)
        private var onLinkTap: ((URL) -> Void)?
        private var textRectOffset: UIOffset = .zero
        private var sourceText = NSAttributedString(string: "")
        private var adjustsFontSizeToFitWidth = false
        private var minimumScaleFactor: CGFloat = 0
        private var fittingWidth: CGFloat?

        public init() {
            super.init(frame: .zero)
            textView.isEditable = false
            textView.isScrollEnabled = false
            textView.backgroundColor = .clear
            textView.textContainerInset = .zero
            textView.textContainer.lineFragmentPadding = 0
            textView.delegate = self
            addSubview(textView)
            accessibilityElements = [textView]
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
            for (url, range) in TextLinkDetectionType.detectLinks(
                in: model.attributedText,
                types: model.linkDetectionTypes
            ) {
                var effectiveRange = NSRange()
                let link = text.attribute(.link, at: range.location, longestEffectiveRange: &effectiveRange, in: range)
                // Preserve explicit links anywhere in the detected range.
                if link == nil && effectiveRange == range {
                    text.addAttribute(.link, value: url, range: range)
                }
            }
            sourceText = text
            fittingWidth = nil
            applyText(fitting: bounds.width)

            textView.accessibilityElementOverride = model.isAccessibilityElement
            textView.accessibilityElementsHidden = model.isAccessibilityElement == false
            accessibilityElements = model.isAccessibilityElement == false ? [] : [textView]
            textView.additionalAccessibilityTraits = model.accessibilityTraits.map(UIAccessibilityTraits.init(with:)) ?? []
            textView.textAccessibilityRole = model.textAccessibilityRole
            textView.accessibilityAttributedLabel = model.accessibilityAttributedLabel
            textView.accessibilityAttributedValue = model.accessibilityAttributedValue
            textView.accessibilityAttributedHint = model.accessibilityAttributedHint
            textView.accessibilityIdentifier = model.accessibilityIdentifier
            textView.accessibilityCustomActions = model.accessibilityCustomActions.map { action in
                UIAccessibilityCustomAction(name: action.name) { _ in action.onActivation() }
            }
            textView.layer.shadowOpacity = Float(model.shadow?.opacity ?? 0)
            textView.layer.shadowRadius = model.shadow?.radius ?? 0
            textView.layer.shadowOffset = model.shadow.map { CGSize(
                width: $0.offset.horizontal,
                height: $0.offset.vertical
            ) } ?? .zero
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
               width > 0, width.isFinite, minimumScaleFactor < 1, sourceText.size().width > width
            {
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
            if adjustsFontSizeToFitWidth && size.width != bounds.width { setNeedsLayout() }
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
