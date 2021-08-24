import BlueprintUI
import UIKit


/// Displays text content.
public struct Label: ProxyElement {

    /// The text to be displayed.
    public var text: String

    public var font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
    public var color: UIColor = .black
    public var alignment: NSTextAlignment = .left
    public var numberOfLines: Int = 0
    public var lineBreakMode: NSLineBreakMode = .byWordWrapping
    public var lineHeight: LineHeight = .font
    public var isAccessibilityElement = true
    public var accessibilityTraits: Set<AccessibilityElement.Trait>?

    public init(text: String, configure: (inout Label) -> Void = { _ in }) {
        self.text = text
        configure(&self)
    }

    private var effectiveLineBreakMode: NSLineBreakMode {
        // These line break modes don't work when numberOfLines is 1, and they break line height adjustments.
        // Normalize them to clipping mode instead.
        if numberOfLines == 1 && (lineBreakMode == .byCharWrapping || lineBreakMode == .byWordWrapping) {
            return .byClipping
        }
        return lineBreakMode
    }

    private var attributedText: NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = effectiveLineBreakMode

        switch lineHeight {
        case .custom(let lineHeight, _):
            paragraphStyle.minimumLineHeight = lineHeight
            paragraphStyle.maximumLineHeight = lineHeight

        case .font:
            // do nothing, use default behavior
            break
        }

        return NSAttributedString(
            string: text,
            attributes: [
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.foregroundColor: color,
                NSAttributedString.Key.paragraphStyle: paragraphStyle,
            ]
        )
    }

    public var elementRepresentation: Element {
        AttributedLabel(attributedText: attributedText) { label in
            label.numberOfLines = numberOfLines
            label.isAccessibilityElement = isAccessibilityElement
            label.accessibilityTraits = accessibilityTraits

            switch lineHeight {
            case .custom(let lineHeight, .top):
                let leading = lineHeight - font.lineHeight
                label.textRectOffset = UIOffset(horizontal: 0, vertical: -leading)

            case .custom(let lineHeight, .center):
                let halfLeading = (lineHeight - font.lineHeight) / 2
                label.textRectOffset = UIOffset(horizontal: 0, vertical: -halfLeading)

            case .font, .custom(_, .bottom):
                // do nothing, use default behavior
                break
            }
        }
    }
}

extension Label {
    public enum LineHeight: Equatable {
        public enum Alignment: Equatable {
            /// Align text to the top of the available line height, with extra space added at the bottom.
            /// This makes line height behave like traditional leading.
            case top

            /// Center text within the available line height. This makes line height behave like half-leading,
            /// and matches the model used by CSS.
            case center

            /// Align text to the bottom of the available line height, with extra space added at the top.
            /// This is the default behavior of `UILabel` on iOS.
            case bottom
        }

        /// Use the default line height of the label's font.
        case font

        /// Use a custom line height and alignment.
        case custom(lineHeight: CGFloat, alignment: Alignment = .bottom)
    }
}
