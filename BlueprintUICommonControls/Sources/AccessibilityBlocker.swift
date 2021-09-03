import BlueprintUI
import UIKit


/// Blocks all accessibility on the element, so that it is
/// is no longer an accessibility element, and its children are
/// hidden from the accessibility system.
public struct AccessibilityBlocker: Element {

    public var wrapped: Element

    /// Creates a new `AccessibilityBlocker` wrapping the provided element.
    public init(wrapping element: Element) {
        wrapped = element
    }

    //
    // MARK: Element
    //

    public var content: ElementContent {
        ElementContent(child: wrapped)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        UIView.describe { config in
            config[\.isAccessibilityElement] = false
            config[\.accessibilityElementsHidden] = true
        }
    }
}


extension Element {

    /// Blocks all accessibility on the element, so that it is
    /// is no longer an accessibility element, and its children are
    /// hidden from the accessibility system.
    public func blockAccessibility() -> AccessibilityBlocker {
        AccessibilityBlocker(wrapping: self)
    }
}
