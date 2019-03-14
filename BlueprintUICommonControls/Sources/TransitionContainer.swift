import BlueprintUI
import UIKit


/// Wraps a content element and adds transitions when the element appears,
/// disappears, or changes layout.
public struct TransitionContainer: Element {

    public var appearingTransition: VisibilityTransition = .fade
    public var disappearingTransition: VisibilityTransition = .fade
    public var layoutTransition: LayoutTransition = .specific(AnimationAttributes())

    public var wrappedElement: Element

    public init(wrapping element: Element) {
        self.wrappedElement = element
    }

    public var content: ElementContent {
        return ElementContent(child: wrappedElement)
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return UIView.describe { config in
            config.appearingTransition = appearingTransition
            config.disappearingTransition = disappearingTransition
            config.layoutTransition = layoutTransition
        }
    }

}
