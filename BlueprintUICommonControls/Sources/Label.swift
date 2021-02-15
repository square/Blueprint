import BlueprintUI
import UIKit


/// Displays text content.
public struct Label: ProxyElement {

    /// The text to be displayed.
    public var text: String {
        didSet { self.updateBackingLabel() }
    }
    
    public var font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize) {
        didSet { self.updateBackingLabel() }
    }
    
    public var color: UIColor = .black {
        didSet { self.updateBackingLabel() }
    }
    
    public var alignment: NSTextAlignment = .left {
        didSet { self.updateBackingLabel() }
    }
    
    public var numberOfLines: Int = 0 {
        didSet { self.updateBackingLabel() }
    }
    
    public var lineBreakMode: NSLineBreakMode = .byWordWrapping {
        didSet { self.updateBackingLabel() }
    }
    
    public var lineHeight: LineHeight = .font {
        didSet { self.updateBackingLabel() }
    }
    
    public var isAccessibilityElement = false {
        didSet { self.updateBackingLabel() }
    }
    
    private var backingLabel : AttributedLabel? = nil
    private var finishedInit : Bool = false

    public init(text: String, configure: (inout Label) -> Void = { _ in }) {
        self.text = text
        configure(&self)
        self.finishedInit = true
        self.updateBackingLabel()
    }

    public var elementRepresentation: Element {
        self.backingLabel ?? self.makeBackingLabel()
    }
    
    private mutating func updateBackingLabel() {
        self.backingLabel = self.makeBackingLabel()
    }
    
    private func makeBackingLabel() -> AttributedLabel {
        AttributedLabel(attributedText: self.makeAttributedText()) { label in
            label.numberOfLines = numberOfLines
            label.isAccessibilityElement = isAccessibilityElement

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
    
    private func makeAttributedText() -> NSAttributedString {
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
                NSAttributedString.Key.paragraphStyle: paragraphStyle
            ]
        )
    }
    
    private var effectiveLineBreakMode: NSLineBreakMode {
        // These line break modes don't work when numberOfLines is 1, and they break line height adjustments.
        // Normalize them to clipping mode instead.
        if numberOfLines == 1 && (lineBreakMode == .byCharWrapping || lineBreakMode == .byWordWrapping) {
            return .byClipping
        }
        return lineBreakMode
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
