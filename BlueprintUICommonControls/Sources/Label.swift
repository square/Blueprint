import BlueprintUI
import UIKit


/// Displays text content.
public struct Label : ProxyElement {

    /// The text to be displayed.
    public var text: String
    
    /// The font used to display the label.
    public var font: UIFont
    
    /// The color of the label.
    /// Defaults to black.
    public var color: UIColor
    
    /// The alignment of the label.
    /// Defaults to left alignment.
    public var alignment: NSTextAlignment
    
    /// The max number of lines the label will render.
    /// Defaults to zero, which is as many lines as needed.
    public var numberOfLines: Int
    
    /// The line break mode for displaying text.
    /// Defaults to word wrapping.
    public var lineBreakMode: NSLineBreakMode
    
    //
    // MARK: Initialization
    //

    /// Creates a new label with the provided text and options.
    /// You can further customize the label within the `configure` block.
    public init(
        text: String,
        font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize),
        color: UIColor = .black,
        alignment: NSTextAlignment = .left,
        numberOfLines: Int = 0,
        lineBreakMode: NSLineBreakMode = .byWordWrapping,
        configure: (inout Label) -> Void = { _ in }
    ) {
        self.text = text
        
        self.font = font
        self.color = color
        self.alignment = alignment
        self.numberOfLines = numberOfLines
        self.lineBreakMode = lineBreakMode
        
        configure(&self)
    }
    
    //
    // MARK: ProxyElement
    //

    public var elementRepresentation: Element {
        return AttributedLabel(text: self.attributedText, numberOfLines: self.numberOfLines)
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
            ]
        )
    }
}
