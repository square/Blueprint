import BlueprintUI
import UIKit

public struct AttributedLabel: Element, Hashable {

    public var attributedText: NSAttributedString
    public var numberOfLines: Int = 0
    public var isAccessibilityElement = false

    /// An offset that will be applied to the rect used by `drawText(in:)`.
    ///
    /// This can be used to adjust the positioning of text within each line's frame, such as adjusting
    /// the way text is distributed within the line height.
    public var textRectOffset: UIOffset = .zero

    public init(attributedText: NSAttributedString, configure : (inout Self) -> () = { _ in }) {
        self.attributedText = attributedText
        
        configure(&self)
    }

    public var content: ElementContent {
        struct Measurer: Measurable {
            private static let prototypeLabel = LabelView()

            var model: AttributedLabel

            func measure(in constraint: SizeConstraint) -> CGSize {
                let label = Self.prototypeLabel
                model.update(label: label)
                return label.sizeThatFits(constraint.maximum)
            }
        }

        return ElementContent(layout: LabelLayout(measurer: Measurer(model: self)))
    }

    private func update(label: LabelView) {
        label.attributedText = attributedText
        label.numberOfLines = numberOfLines
        label.isAccessibilityElement = isAccessibilityElement
        label.textRectOffset = textRectOffset
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        return LabelView.describe { (config) in
            config.apply(update)
        }
    }
}

extension AttributedLabel {
    private final class LabelView: UILabel {
        var textRectOffset: UIOffset = .zero {
            didSet {
                if oldValue != textRectOffset {
                    setNeedsDisplay()
                }
            }
        }

        override func drawText(in rect: CGRect) {
            super.drawText(in: rect.offsetBy(dx: textRectOffset.horizontal, dy: textRectOffset.vertical))
        }
    }

    private struct LabelLayout: Layout {
        private let measurer: Measurable

        init(measurer: Measurable) {
            self.measurer = measurer
        }

        func measure(in constraint: SizeConstraint, items: [(traits: (), content: Measurable)]) -> CGSize {
            measurer.measure(in: constraint)
        }

        func layout(size: CGSize, items: [(traits: (), content: Measurable)]) -> [LayoutAttributes] {
            let size = measurer.measure(in: SizeConstraint(size))
            var attributes = LayoutAttributes(size: size)
            attributes.pixelRounding = .size
            return [attributes]
        }
    }
}

extension UIOffset: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(horizontal)
        hasher.combine(vertical)
    }
}
