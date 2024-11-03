import BlueprintUI
import UIKit


/// Displays text content.
public struct Label: ProxyElement {

    /// The text to be displayed.
    public var text: String

    public var font: UIFont = UIFont.systemFont(ofSize: UIFont.labelFontSize)
    public var color: UIColor = .black
    public var alignment: NSTextAlignment = .left
    public var numberOfLines: Int = 0
    public var lineBreakMode: NSLineBreakMode = .byTruncatingTail
    public var lineHeight: LineHeight = .font

    /// A Boolean value that determines whether the label reduces the text’s font
    /// size to fit the title string into the label’s bounding rectangle.
    ///
    /// Normally, the label draws the text with the font you specify in the font property.
    /// If this property is true, and the text in the text property exceeds the label’s bounding rectangle,
    /// the label reduces the font size until the text fits or it has scaled the font down to the minimum
    /// font size. The default value for this property is false.
    ///
    /// If you change it to true, be sure that you also set an appropriate minimum
    /// font scale by modifying the minimumScaleFactor property.
    ///
    /// This autoshrinking behavior is only intended for use with a single-line label.
    public var adjustsFontSizeToFitWidth: Bool = false

    /// The minimum scale factor for the label’s text.
    ///
    /// If the adjustsFontSizeToFitWidth is true, use this property to specify the
    /// smallest multiplier for the current font size that yields an acceptable
    /// font size for the label’s text.
    ///
    /// If you specify a value of 0 for this property, the label doesn't scale the text down.
    /// The default value of this property is 0.
    public var minimumScaleFactor: CGFloat = 0

    /// A Boolean value that determines whether the label tightens text before truncating.
    ///
    /// When the value of this property is true, the label tightens intercharacter spacing
    /// of its text before allowing any truncation to occur. The label determines the
    /// maximum amount of tightening automatically based on the font, current line width,
    /// line break mode, and other relevant information.
    ///
    /// This autoshrinking behavior is only intended for use with a single-line label.
    ///
    /// The default value of this property is false.
    public var allowsDefaultTighteningForTruncation: Bool = false

    /// A shadow to display behind the label's text. Defaults to no shadow.
    public var shadow: TextShadow?

    /// Determines if the label should be included when navigating the UI via accessibility.
    public var isAccessibilityElement = true

    /// A localized string that represents the current value of the accessibility element.
    ///
    /// The value is a localized string that contains the current value of an element.
    /// For example, the value of a slider might be 9.5 or 35% and the value of a text field is the text it contains.
    public var accessibilityValue: String?

    /// A localized string that describes the result of performing an action on the element, when the result is non-obvious.
    public var accessibilityHint: String?

    /// A set of accessibility traits that should be applied to the label, these will be merged with any existing traits.
    public var accessibilityTraits: Set<AccessibilityElement.Trait>?

    /// An array containing one or more `AccessibilityElement.CustomAction`s, defining additional supported actions. Assistive technologies, such as VoiceOver, will display your custom actions to the user at appropriate times.
    public var accessibilityCustomActions: [AccessibilityElement.CustomAction] = []


    public init(text: String, configure: (inout Label) -> Void = { _ in }) {
        self.text = text
        configure(&self)
    }

    private var attributedText: NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = lineBreakMode

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
            label.shadow = shadow
            label.isAccessibilityElement = isAccessibilityElement
            label.accessibilityValue = accessibilityValue
            label.accessibilityHint = accessibilityHint
            label.accessibilityTraits = accessibilityTraits
            label.accessibilityCustomActions = accessibilityCustomActions
            label.adjustsFontSizeToFitWidth = adjustsFontSizeToFitWidth
            label.minimumScaleFactor = minimumScaleFactor
            label.allowsDefaultTighteningForTruncation = allowsDefaultTighteningForTruncation

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

            label.needsTextNormalization = NSAttributedString.needsNormalizingForView(
                hasLinks: false,
                lineLimit: numberOfLines,
                lineBreaks: lineBreakMode
            )
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
