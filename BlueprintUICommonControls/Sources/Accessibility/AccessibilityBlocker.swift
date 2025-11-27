import BlueprintUI
import UIKit


/// Blocks all accessibility on the element, so that it is
/// is no longer an accessibility element, and its children are
/// hidden from the accessibility system.
public struct AccessibilityBlocker: Element {

    /// The element whose accessibility information will be blocked.
    public var wrapped: Element

    /// If the `AccessibilityBlocker` is currently blocking accessibility.
    public var isBlocking: Bool

    /// Creates a new `AccessibilityBlocker` wrapping the provided element.
    public init(
        isBlocking: Bool = true,
        wrapping element: Element
    ) {
        self.isBlocking = isBlocking

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
            config[\.accessibilityElementsHidden] = isBlocking
        }
    }
}


extension Element {

    /// Blocks all accessibility on the element, so that it is
    /// is no longer an accessibility element, and its children are
    /// hidden from the accessibility system.
    public func blockAccessibility(isBlocking: Bool = true) -> AccessibilityBlocker {
        AccessibilityBlocker(isBlocking: isBlocking, wrapping: self)
    }
}
