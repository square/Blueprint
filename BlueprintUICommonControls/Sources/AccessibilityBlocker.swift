import BlueprintUI
import UIKit

public struct AccessibilityBlocker: Element {

    public var wrappedElement: Element

    public init(wrapping element: Element) {
        self.wrappedElement = element
    }

    public var content: ElementContent {
        return ElementContent(child: wrappedElement)
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return UIView.describe { config in
            config[\.isAccessibilityElement] = false
            config[\.accessibilityElementsHidden] = true
        }
    }
}

public extension Element {
    func disableAccessibility() -> AccessibilityBlocker {
        AccessibilityBlocker(wrapping: self)
    }
}
