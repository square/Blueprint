import UIKit


/**
 Wraps a content element and adds transitions when the element appears, disappears, or changes layout.
 
 
 */
public struct Transition<Wrapped:Element> : Element {

    public var onAppear: TransitionAnimation?
    public var onDisappear: TransitionAnimation?
    
    public var layoutTransition: LayoutTransition

    public var wrapped : Wrapped
    
    public init(
        animation: TransitionAnimation,
        layout: LayoutTransition = .specific(AnimationOptions()),
        wrapping element: Wrapped
    ) {
        self.init(
            onAppear: animation,
            onDisappear: animation,
            layout: layout,
            wrapping: element
        )
    }

    public init(
        onAppear: TransitionAnimation? = nil,
        onDisappear: TransitionAnimation? = nil,
        layout: LayoutTransition = .specific(AnimationOptions()),
        wrapping element: Wrapped
    ) {
        self.onAppear = onAppear
        self.onDisappear = onDisappear
        
        self.layoutTransition = layout
        
        self.wrapped = element
    }

    public var content: ElementContent {
        return ElementContent(child: wrapped)
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return TransitionContainerView.describe { config in
            config.onAppear = onAppear
            config.onDisappear = onDisappear
            config.layoutTransition = layoutTransition
        }
    }
}


/**
 A view class used to wrap elements that are within a `TransitionContainer`.
 The animations of the `TransitionContainer` are applied to this view.
 
 This is used instead of a plain `UIView` so when examining the view hierarchy,
 there's an indication of where the view is coming from.
 */
public final class TransitionContainerView : UIView { }
