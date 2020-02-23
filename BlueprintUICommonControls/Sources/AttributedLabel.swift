import BlueprintUI
import UIKit

// Displays attributed text in a label.
public struct AttributedLabel: Element {

    /// The text shown within the label.
    public var text: NSAttributedString
    
    /// The number of lines the label should display.
    public var numberOfLines: Int
    
    /// The scale to which pixel measurements will be rounded. Defaults to `UIScreen.main.scale`.
    public var roundingScale: CGFloat = UIScreen.main.scale

    /// Creates a new label with the provided text and number of lines to display.
    public init(
        text: NSAttributedString,
        numberOfLines: Int = 0
    ) {
        self.text = text
        self.numberOfLines = numberOfLines
    }
    
    /**
     Keep around a label to use for measurement and sizing.
     
     We would usually do this using `NSString` or `NSAttributedString's` `boundingRect` family of methods,
     but these do not let you specify a `numberOfLines` parameter, which is critical to correct sizing. Further,
     `UILabel`'s sizing is complex enough that we prefer to defer to its implementation, rather than atttempting
     to re-implement it.
     
     As such, we will allocate this label once and then use it to measure by setting its text and attributes. A static
     label is acceptable because layout code operates on the main thread.
     */
    private static let measurementLabel = UILabel()

    public var content: ElementContent {
        assert(Thread.isMainThread, "Expected sizing to occur on the main thread. This is required due to the use of `measurementLabel`.")

        return ElementContent { constraint in
            let label = AttributedLabel.measurementLabel
            let fittingSize = constraint.maximum
            
            // Configure the measurement label to prepare it for measuring our text.
            
            let description = self.backingViewDescription(bounds: CGRect(origin: .zero, size: fittingSize), subtreeExtent: nil)!
            
            description.apply(to: label)
            
            // Determine the returned size.
            
            var size = label.sizeThatFits(fittingSize)
            
            // Constrain the returned size from the label to the
            // constraint's maximum size. UILabel can return a size larger
            // than the provided size, and we want to stay within the provided size.
            
            size.width = min(size.width, fittingSize.width)
            size.height = min(size.height, fittingSize.height)

            return size
        }
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return UILabel.describe { config in
            config[\.attributedText] = text
            config[\.numberOfLines] = numberOfLines
        }
    }
}
