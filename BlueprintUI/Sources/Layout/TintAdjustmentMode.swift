import CoreGraphics
import UIKit

/// `TintAdjustmentMode` conditionally modifies the tint adjustment mode of its wrapped element.
///
/// - Note: When a tint adjustment mode is applied, any elements within the wrapped element will adopt the parent's tint adjustment mode.
public struct TintAdjustmentMode: Element {
    public var tintAdjustmentMode: UIView.TintAdjustmentMode

    public var wrappedElement: Element

    public init(_ tintAdjustmentMode: UIView.TintAdjustmentMode, wrapping element: Element) {
        self.tintAdjustmentMode = tintAdjustmentMode
        wrappedElement = element
    }

    public var content: ElementContent {
        ElementContent(child: wrappedElement, layout: Layout(tintAdjustmentMode: tintAdjustmentMode))
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }

    private struct Layout: SingleChildLayout {
        var tintAdjustmentMode: UIView.TintAdjustmentMode

        func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {
            child.measure(in: constraint)
        }

        func layout(size: CGSize, child: Measurable) -> LayoutAttributes {
            var attributes = LayoutAttributes(size: size)
            attributes.tintAdjustmentMode = tintAdjustmentMode
            return attributes
        }

        func sizeThatFits(
            proposal: SizeConstraint,
            subelement: Subelement,
            environment: Environment,
            cache: inout Cache
        ) -> CGSize {
            subelement.sizeThatFits(proposal)
        }

        func placeSubelement(
            in size: CGSize,
            subelement: Subelement,
            environment: Environment,
            cache: inout ()
        ) {
            subelement.attributes.tintAdjustmentMode = tintAdjustmentMode
        }
    }
}

extension Element {
    /// Conditionally modifies the tint adjustment mode of its wrapped element.
    ///
    /// - Note: When a tint adjustment mode is applied, any elements within the wrapped element will adopt the parent's tint adjustment mode.
    public func tintAdjustmentMode(_ tintAdjustmentMode: UIView.TintAdjustmentMode) -> TintAdjustmentMode {
        TintAdjustmentMode(tintAdjustmentMode, wrapping: self)
    }
}
