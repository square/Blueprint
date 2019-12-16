import BlueprintUI
import UIKit

public struct AttributedLabel: Element {

    public var attributedText: NSAttributedString
    public var numberOfLines: Int
    /// The scale to which pixel measurements will be rounded. Defaults to `UIScreen.main.scale`.
    public var roundingScale: CGFloat = UIScreen.main.scale

    public init(attributedText: NSAttributedString, numberOfLines: Int = 0) {
        self.attributedText = attributedText
        self.numberOfLines = numberOfLines
    }
    
    /**
     Keep around a label to use for measurement and sizing.
     
     We would usually do this using NSString or NSAttributedString's boundingRect family of methods,
     but these do not let you specify a `numberOfLines` parameter, which is critical to correct sizing.
     
     As such, we will allocate this label once and then use it to measure by setting its text and attributes.
     */
    static let measurementLabel = UILabel()

    public var content: ElementContent {
        
        return ElementContent { constraint in
            let label = AttributedLabel.measurementLabel
            let description = self.backingViewDescription(bounds: CGRect(origin: .zero, size: constraint.maximum), subtreeExtent: nil)!
            
            description.apply(to: label)
            label.attributedText = self.attributedText
            
            var size = label.sizeThatFits(constraint.maximum)
            
            size.width = size.width.rounded(.up, by: self.roundingScale)
            size.height = size.height.rounded(.up, by: self.roundingScale)
            
            size.width = min(size.width, constraint.maximum.width, size.width)

            return size
        }
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return UILabel.describe { (config) in
            config[\.attributedText] = attributedText
            config[\.numberOfLines] = numberOfLines
        }
    }

}
