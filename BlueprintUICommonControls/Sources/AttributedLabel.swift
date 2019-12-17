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

    public var content: ElementContent {
        return ElementContent { constraint in
            var size = StringSizingCache.default.size(
                with: constraint.maximum,
                string: self.attributedText,
                numberOfLines: self.numberOfLines
            )
            
            size.width = size.width.rounded(.up, by: self.roundingScale)
            size.height = size.height.rounded(.up, by: self.roundingScale)
            
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
