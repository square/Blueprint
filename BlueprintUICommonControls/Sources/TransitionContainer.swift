import BlueprintUI
import UIKit


/// Wraps a content element and adds transitions when the element appears,
/// disappears, or changes layout.
public struct TransitionContainer: Element {

    public var appearingTransition: VisibilityTransition
    public var disappearingTransition: VisibilityTransition
    public var layoutTransition: LayoutTransition

    public var wrappedElement: Element

    public init(
        wrapping element: Element,
        appearingTransition: VisibilityTransition = .fade,
        disappearingTransition: VisibilityTransition = .fade,
        layoutTransition: LayoutTransition = .specific(AnimationAttributes())
    ) {
        self.wrappedElement = element
        self.appearingTransition = appearingTransition
        self.disappearingTransition = disappearingTransition
        self.layoutTransition = layoutTransition
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

public extension Element {

    /// Wraps the element in a transition container to provide an animated transition.
    ///
    /// - Parameters:
    ///   - appear: The transition to use when the element appears. By default, `.none`.
    ///   - disappear: The transition to use when the element disappears. By default, `.none`.
    ///   - layout: The animation to use when the element changes layout. By default, `.none`.
    func transition(
        appear: VisibilityTransition = .none,
        disappear: VisibilityTransition = .none,
        layout: LayoutTransition = .none
    ) -> TransitionContainer {
        TransitionContainer(
            wrapping: self,
            appearingTransition: appear,
            disappearingTransition: disappear,
            layoutTransition: layout
        )
    }

    /// Wraps the element in a transition container to provide an animated transition when its visibility changes.
    ///
    /// - Parameters:
    ///   - appearAndDisappear: The transition to use when the element appears and disappears.
    func transition(appearAndDisappear: VisibilityTransition) -> TransitionContainer {
        TransitionContainer(
            wrapping: self,
            appearingTransition: appearAndDisappear,
            disappearingTransition: appearAndDisappear,
            layoutTransition: .none
        )
    }
}
