import BlueprintUI
import UIKit


public struct AccessibilityBlocker: Element {

    public var wrapped: Element

    public init(wrapping element: Element) {
        self.wrapped = element
    }

    public var content: ElementContent {
        return ElementContent(child: wrapped)
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return UIView.describe { config in
            config[\.isAccessibilityElement] = false
            config[\.accessibilityElementsHidden] = true
        }
    }
}

public extension Element {
    func blockAccessibility() -> AccessibilityBlocker {
        AccessibilityBlocker(wrapping: self)
    }
}
