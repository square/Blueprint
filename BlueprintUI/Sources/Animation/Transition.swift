import UIKit


/**
 Wraps a content element and adds transitions when the element appears, disappears, or changes layout.
 */
public struct Transition : Element {

    /// The transition to use when the wrapped element is first presented on screen.
    public var onAppear: TransitionAnimation?
    
    /// The transition to use when the wrapped element is removed from the screen.
    public var onDisappear: TransitionAnimation?
    
    /// The layout transition to use when an already on-screen element is updated.
    public var onLayout: LayoutTransition

    /// The element which will be transitioned in, out, or transitioned during layout.
    public var wrapped : Element
    
    //
    // MARK: Initialization
    //
    
    /// Creates a new `Transition` with both `onAppear` and `onDisappear` set to the provided `animation`.
    public init(
        animation: TransitionAnimation,
        layout: LayoutTransition = .specific(AnimationOptions()),
        wrapping element: Element
    ) {
        self.init(
            onAppear: animation,
            onDisappear: animation,
            layout: layout,
            wrapping: element
        )
    }

    /**
     Creates a new `Transition` with the provided options.
    
     If you only provide one of `onAppear` or `onDisappear`, only that direction of appearance
     transition will be animated. The other one will be performed with no animation.
     */
    public init(
        onAppear: TransitionAnimation? = nil,
        onDisappear: TransitionAnimation? = nil,
        layout: LayoutTransition = .specific(AnimationOptions()),
        wrapping element: Element
    ) {
        self.onAppear = onAppear
        self.onDisappear = onDisappear
        
        self.onLayout = layout
        
        self.wrapped = element
    }
    
    //
    // MARK: Element
    //

    public var content: ElementContent {
        return ElementContent(child: wrapped)
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return TransitionContainerView.describe { config in
            config.onAppear = onAppear
            config.onDisappear = onDisappear
            config.onLayout = onLayout
        }
    }
}


/**
 A view class used to wrap elements that are within a `TransitionContainer`.
 The animations of the `TransitionContainer` are applied to this view.
 
 This is used instead of a plain `UIView` so when examining the view hierarchy,
 there's an indication of where the view is coming from.
 */
final class TransitionContainerView : UIView { }
