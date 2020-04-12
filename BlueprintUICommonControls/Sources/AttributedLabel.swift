import BlueprintUI
import UIKit

public struct AttributedLabel: Element {

    public var attributedText: NSAttributedString
    public var numberOfLines: Int = 0
    /// The scale to which pixel measurements will be rounded. Defaults to `UIScreen.main.scale`.
    public var roundingScale: CGFloat = UIScreen.main.scale

    public init(attributedText: NSAttributedString) {
        self.attributedText = attributedText
    }

    public var content: ElementContent {
        ElementContent { constraint in
            var size = self.attributedText.boundingRect(
                with: constraint.maximum,
                options: [.usesLineFragmentOrigin],
                context: nil
            ).size
            
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
