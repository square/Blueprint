import BlueprintUI
import UIKit

public struct AttributedLabel: Element, Hashable {

    public var attributedText: NSAttributedString
    public var numberOfLines: Int = 0

    /// An offset that will be applied to the rect used by `drawText(in:)`.
    ///
    /// This can be used to adjust the positioning of text within each line's frame, such as adjusting
    /// the way text is distributed within the line height.
    public var textRectOffset: UIOffset = .zero

    public var isAccessibilityElement = true
    public var accessibilityTraits: Set<AccessibilityElement.Trait>?

    public init(attributedText: NSAttributedString, configure: (inout Self) -> Void = { _ in }) {
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

        return ElementContent(
            measurable: Measurer(model: self),
            measurementCachingKey: .init(type: Self.self, input: self)
        )
    }

    private func update(label: LabelView) {
        label.attributedText = attributedText
        label.numberOfLines = numberOfLines
        label.textRectOffset = textRectOffset
        label.isAccessibilityElement = isAccessibilityElement
        updateAccessibilityTraits(label)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        return LabelView.describe { config in
            config.apply(update)
        }
    }

    private func updateAccessibilityTraits(_ label: UILabel) {
        if let traits = accessibilityTraits {
            var union = label.accessibilityTraits.union(UIAccessibilityTraits(withSet: traits))
            // UILabel has the `.staticText` trait by default. If we explicitly set `.updatesFrequently` this should be removed.
            if traits.contains(.updatesFrequently) && label.accessibilityTraits.contains(.staticText) {
                union.subtract(.staticText)
            }
            label.accessibilityTraits = union
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
}

extension UIOffset: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(horizontal)
        hasher.combine(vertical)
    }
}
