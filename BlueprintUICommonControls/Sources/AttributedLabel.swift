import BlueprintUI
import UIKit

public struct AttributedLabel: Element, Hashable {

    public var attributedText: NSAttributedString
    public var numberOfLines: Int = 0
    
    /// The scale to which pixel measurements will be rounded. Defaults to `UIScreen.main.scale`.
    public var roundingScale: CGFloat = UIScreen.main.scale

    public init(attributedText: NSAttributedString, configure : (inout Self) -> () = { _ in }) {
        self.attributedText = attributedText
        
        configure(&self)
    }

    public var content: ElementContent {
        struct Measurer: Measurable {

            var attributedText: NSAttributedString
            var roundingScale: CGFloat

            func measure(in constraint: SizeConstraint) -> CGSize {
                var size = attributedText.boundingRect(
                    with: constraint.maximum,
                    options: [.usesLineFragmentOrigin],
                    context: nil)
                    .size
                size.width = size.width.rounded(.up, by: roundingScale)
                size.height = size.height.rounded(.up, by: roundingScale)

                return size
            }
        }

        return ElementContent(
            measurable: Measurer(attributedText: attributedText, roundingScale: roundingScale),
            measurementCachingKey: .init(type: Self.self, input: self)
        )
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return UILabel.describe { (config) in
            config[\.attributedText] = attributedText
            config[\.numberOfLines] = numberOfLines
        }
    }

}
