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

    /// Determines if the label should be included when navigating the UI via accessibility.
    public var isAccessibilityElement = true

    /// Controls how to adjust the size of the text when it does not fit in the given layout.
    public var textFitting: TextFittingAdjustment = .noAdjustment

    /// A set of accessibility traits that should be applied to the label, these will be merged with any existing traits.
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

        textFitting.apply(to: label)

        updateAccessibilityTraits(label)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        LabelView.describe { config in
            config.frameRoundingBehavior = .prioritizeSize
            config.apply(update)
        }
    }

    private func updateAccessibilityTraits(_ label: UILabel) {
        if let traits = accessibilityTraits {
            var union = label.accessibilityTraits.union(UIAccessibilityTraits(with: traits))
            // UILabel has the `.staticText` trait by default. If we explicitly set `.updatesFrequently` this should be removed.
            if traits.contains(.updatesFrequently) && label.accessibilityTraits.contains(.staticText) {
                union.subtract(.staticText)
            }
            label.accessibilityTraits = union
        }
    }
}

/// Provides a way to allow the adjustment of the text within a label when it become too wide to fit within a label.
public enum TextFittingAdjustment: Hashable {

    /// No adjustment is performed.
    case noAdjustment

    /// The provided adjustment is applied.
    case adjusts(Adjusts)

    /// The provided adjustment is applied.
    public static func adjusts(
        allowsTightening: Bool,
        minimumScale: CGFloat
    ) -> Self {
        .adjusts(
            .init(
                allowsTightening: allowsTightening,
                minimumScale: minimumScale
            )
        )
    }

    /// Controls the adjustments applied to a label when it does not fit in the provided layout rect.
    public struct Adjusts: Hashable {

        /// If the layout should tighten letter spacing when there is not enough spacing to fit the text.
        public var allowsTightening: Bool

        /// When scaling text down, controls the minimum text before it stops scaling down.
        public var minimumScale: CGFloat
    }

    var labelProperties: LabelProperties {
        switch self {
        case .noAdjustment:
            return LabelProperties(
                adjustsFontToFit: false,
                allowsTightening: false,
                minimumScaleFactor: 0
            )
        case .adjusts(let adjustment):
            return LabelProperties(
                adjustsFontToFit: true,
                allowsTightening: adjustment.allowsTightening,
                minimumScaleFactor: adjustment.minimumScale
            )
        }
    }

    struct LabelProperties: Equatable {
        var adjustsFontToFit: Bool
        var allowsTightening: Bool
        var minimumScaleFactor: CGFloat

        func apply(to label: UILabel) {
            label.adjustsFontSizeToFitWidth = adjustsFontToFit
            label.allowsDefaultTighteningForTruncation = allowsTightening
            label.minimumScaleFactor = minimumScaleFactor
        }
    }

    func apply(to label: UILabel) {
        labelProperties.apply(to: label)
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
