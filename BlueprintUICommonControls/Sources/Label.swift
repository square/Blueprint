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
    
    /// The scale to which pixel measurements will be rounded. Defaults to `UIScreen.main.scale`.
    public var roundingScale: CGFloat = UIScreen.main.scale

    public init(text: String, configure: (inout Label) -> Void = { _ in }) {
        self.text = text
        configure(&self)
    }
    
    private var attributedText: NSAttributedString {
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = lineBreakMode
        return NSAttributedString(
            string: text,
            attributes: [
                NSAttributedString.Key.font: font,
                NSAttributedString.Key.foregroundColor: color,
                NSAttributedString.Key.paragraphStyle: paragraphStyle
            ])
    }

    public var elementRepresentation: Element {
        AttributedLabel(attributedText: attributedText) { label in
            label.numberOfLines = self.numberOfLines
            label.roundingScale = self.roundingScale
        }
    }
}
