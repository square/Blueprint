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
    ///   - onAppear: The transition to use when the element appears. By default, `.none`.
    ///   - onDisappear: The transition to use when the element disappears. By default, `.none`.
    ///   - onLayout: The animation to use when the element changes layout. By default, `.none`.
    func transition(
        onAppear: VisibilityTransition = .none,
        onDisappear: VisibilityTransition = .none,
        onLayout: LayoutTransition = .none
    ) -> TransitionContainer {
        TransitionContainer(
            wrapping: self,
            appearingTransition: onAppear,
            disappearingTransition: onDisappear,
            layoutTransition: onLayout
        )
    }

    /// Wraps the element in a transition container to provide an animated transition when its visibility changes.
    ///
    /// - Parameters:
    ///   - onAppearOrDisappear: The transition to use when the element appears or disappears.
    func transition(_ onAppearOrDisappear: VisibilityTransition) -> TransitionContainer {
        TransitionContainer(
            wrapping: self,
            appearingTransition: onAppearOrDisappear,
            disappearingTransition: onAppearOrDisappear,
            layoutTransition: .none
        )
    }
}
