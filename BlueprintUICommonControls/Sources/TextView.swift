import BlueprintUI
import UIKit

public struct AttributedLabel: Element, Hashable {

    public var attributedText: NSAttributedString
    public var numberOfLines: Int = 0

    /// An offset that will be applied to the rect used by `drawText(in:)`.
    ///
    /// This can be used to adjust the positioning of text within each line's frame, such as adjusting
    /// the way text is distributed within the line height.
    public var textRectOffset: UIOffset = .zero

    /// Determines if the label should be included when navigating the UI via accessibility.
    public var isAccessibilityElement = true

    /// A set of accessibility traits that should be applied to the label, these will be merged with any existing traits.
    public var accessibilityTraits: Set<AccessibilityElement.Trait>?

    public init(attributedText: NSAttributedString, configure: (inout Self) -> Void = { _ in }) {
        self.attributedText = attributedText

        configure(&self)
    }

    public var content: ElementContent {
        struct Measurer: Measurable {
            private static let prototypeLabel = TextViewView()

            var model: AttributedLabel

            func measure(in constraint: SizeConstraint) -> CGSize {
                let label = Self.prototypeLabel
                model.update(label: label)
                return label.sizeThatFits(constraint.maximum)
            }
        }

        return ElementContent(
            measurable: Measurer(model: self),
            measurementCachingKey: .init(type: Self.self, input: self)
        )
    }

    private func update(label: TextViewView) {
        label.attributedText = attributedText
        label.textContainer.maximumNumberOfLines = numberOfLines
        label.textRectOffset = textRectOffset
        label.isAccessibilityElement = isAccessibilityElement
        updateAccessibilityTraits(label)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        TextViewView.describe { config in
            config.frameRoundingBehavior = .prioritizeSize
            config[\.dataDetectorTypes] = .all
            config.apply(update)
        }
    }

    private func updateAccessibilityTraits(_ label: UITextView) {
        if let traits = accessibilityTraits {
            var union = label.accessibilityTraits.union(UIAccessibilityTraits(with: traits))
            // UILabel has the `.staticText` trait by default. If we explicitly set `.updatesFrequently` this should be removed.
            if traits.contains(.updatesFrequently) && label.accessibilityTraits.contains(.staticText) {
                union.subtract(.staticText)
            }
            label.accessibilityTraits = union
        }
    }
}

extension AttributedLabel {

    private final class TextViewView: UITextView, UITextViewDelegate, NSLayoutManagerDelegate {
        var textRectOffset: UIOffset = .zero {
            didSet {
                adjustContentInsets()
            }
        }

        override var contentSize: CGSize {
            didSet {
                adjustContentInsets()
            }
        }

        override init(frame: CGRect, textContainer: NSTextContainer?) {
            super.init(frame: frame, textContainer: textContainer)
            font = .systemFont(ofSize: 17)
            textContainerInset = .zero
            isScrollEnabled = false
            delegate = self
            self.textContainer.lineFragmentPadding = .zero
            self.textContainer.lineBreakMode = .byTruncatingTail
            self.textContainer.layoutManager?.delegate = self
            backgroundColor = .clear
            isEditable = false
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            /// Prevents selection from occurring
            textView.selectedTextRange = nil

            /// Prevents magnifying glass from showing up
            textView.isSelectable = false
            textView.isSelectable = true
        }

        private func adjustContentInsets() {
            let textRange = NSRange(location: 0, length: attributedText.length)
            let textBoundingRect = textContainer.layoutManager?.boundingRect(forGlyphRange: textRange, in: textContainer) ?? .zero
            let centerOffset = (bounds.height - textBoundingRect.height) / 2
            let vertical = textRectOffset.vertical + max(0, centerOffset)
            let horizontal = textRectOffset.horizontal
            let insets = UIEdgeInsets(top: vertical, left: horizontal, bottom: -vertical, right: -horizontal)
            contentInset = insets
        }

        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            scrollView.contentOffset.y = -scrollView.contentInset.top
        }
    }
}
