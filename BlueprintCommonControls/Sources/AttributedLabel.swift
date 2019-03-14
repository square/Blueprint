import Blueprint
import UIKit

public struct AttributedLabel: Element {

    public var attributedText: NSAttributedString
    public var numberOfLines: Int = 0

    public init(attributedText: NSAttributedString) {
        self.attributedText = attributedText
    }

    public var content: ElementContent {
        struct Measurer: Measurable {

            var attributedText: NSAttributedString

            func measure(in constraint: SizeConstraint) -> CGSize {
                var size = attributedText.boundingRect(
                    with: constraint.maximum,
                    options: [.usesLineFragmentOrigin],
                    context: nil)
                    .size
                size.width = ceil(size.width)
                size.height = ceil(size.height)

                return size
            }
        }

        return ElementContent(measurable: Measurer(attributedText: attributedText))
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return UILabel.describe { (config) in
            config[\.attributedText] = attributedText
            config[\.numberOfLines] = numberOfLines
        }
    }

}
