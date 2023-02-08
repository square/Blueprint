@_spi(BlueprintPassthroughView) import BlueprintUI
import UIKit


/// Wraps a content element and adds transitions when the element appears,
/// disappears, or changes layout.
public struct TransitionContainer: Element {

    /// The transition to apply when the wrapped element is appearing.
    public var appearingTransition: VisibilityTransition?
    /// The transition to apply when the wrapped element is disappearing.
    public var disappearingTransition: VisibilityTransition?
    /// The transition to apply when the wrapped element's layout is changing.
    public var layoutTransition: LayoutTransition

    /// The element to which transitions are being applied.
    public var wrappedElement: Element


    /// Create a transition container wrapping an element.
    ///
    /// The created container's default transitions are:
    /// * `appearingTransition`: `fade`
    /// * `disappearingTransition`: `fade`
    /// * `layoutTransition`: `.specific(AnimationAttributes())`
    ///
    /// - Parameters:
    ///   - wrapping: The element to which transitions will be applied.
    @available(*, deprecated, message: "Use TransitionContainer(transitioning:), which has better defaults")
    public init(wrapping element: Element) {
        appearingTransition = .fade
        disappearingTransition = .fade
        layoutTransition = .specific(AnimationAttributes())
        wrappedElement = element
    }

    /// Create a transition container wrapping an element.
    /// - Parameters:
    ///   - appearingTransition: The transition to use when the element appears. By default, no transition.
    ///   - disappearingTransition: The transition to use when the element disappears. By default, no transition.
    ///   - layoutTransition: The transition to use when the element's layout changes. The default value is
    ///     `.inherited`, which means the element will participate in the same transition as its
    ///     nearest ancestor with a specified transition.
    ///   - transitioning: The element to which transitions will be applied.
    public init(
        appearingTransition: VisibilityTransition? = nil,
        disappearingTransition: VisibilityTransition? = nil,
        layoutTransition: LayoutTransition = .inherited,
        transitioning element: Element
    ) {
        self.appearingTransition = appearingTransition
        self.disappearingTransition = disappearingTransition
        self.layoutTransition = layoutTransition
        wrappedElement = element
    }

    public var content: ElementContent {
        ElementContent(child: wrappedElement)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        PassthroughView.describe { config in
            config.appearingTransition = appearingTransition
            config.disappearingTransition = disappearingTransition
            config.layoutTransition = layoutTransition
        }
    }

}

extension Element {

    /// Wraps the element in a transition container to provide an animated transition.
    ///
    /// - Parameters:
    ///   - onAppear: The transition to use when the element appears. By default, no transition.
    ///   - onDisappear: The transition to use when the element disappears. By default, no transition.
    ///   - onLayout: The transition to use when the element's layout changes. The default value is
    ///     `.inherited`, which means the element will participate in the same transition as its
    ///     nearest ancestor with a specified transition.
    public func transition(
        onAppear: VisibilityTransition? = nil,
        onDisappear: VisibilityTransition? = nil,
        onLayout: LayoutTransition = .inherited
    ) -> TransitionContainer {
        TransitionContainer(
            appearingTransition: onAppear,
            disappearingTransition: onDisappear,
            layoutTransition: onLayout,
            transitioning: self
        )
    }

    /// Wraps the element in a transition container to provide an animated transition when its visibility changes.
    ///
    /// - Parameters:
    ///   - onAppearOrDisappear: The transition to use when the element appears or disappears.
    public func transition(_ onAppearOrDisappear: VisibilityTransition) -> TransitionContainer {
        TransitionContainer(
            appearingTransition: onAppearOrDisappear,
            disappearingTransition: onAppearOrDisappear,
            transitioning: self
        )
    }
}
