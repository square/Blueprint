import BlueprintUI
import UIKit

public struct AttributedLabel: Element {

    public var attributedText: NSAttributedString
    public var numberOfLines: Int = 0
    /// The scale to which pixel measurements will be rounded. Defaults to `UIScreen.main.scale`.
    public var roundingScale = RoundingScale.scale(UIScreen.main.scale)

    public init(attributedText: NSAttributedString) {
        self.attributedText = attributedText
    }

    public var content: ElementContent {
        struct Measurer: Measurable {

            var attributedText: NSAttributedString
            var roundingScale: RoundingScale

            func measure(in constraint: SizeConstraint) -> CGSize {
                var size = attributedText.boundingRect(
                    with: constraint.maximum,
                    options: [.usesLineFragmentOrigin],
                    context: nil)
                    .size
                size.width = roundingScale.round(size.width, .up)
                size.height = roundingScale.round(size.height, .up)

                return size
            }
        }

        return ElementContent(measurable: Measurer(attributedText: attributedText, roundingScale: roundingScale))
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return UILabel.describe { (config) in
            config[\.attributedText] = attributedText
            config[\.numberOfLines] = numberOfLines
        }
    }

}
