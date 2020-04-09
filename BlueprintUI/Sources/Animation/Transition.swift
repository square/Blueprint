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
        with animation: TransitionAnimation,
        layout: LayoutTransition = .inherited,
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
     
     You can use this method if you would like to nest multiple animations within each other to create more complex effects.
     
     For example, if you wanted to  have a spin nested in a fade, you would pass:
     
     ```
     Transition(
        onAppear: [.fade, .spin],
        ...
     )
     ```
     
     If you only provide one of `onAppear` or `onDisappear`, only that direction of appearance
     transition will be animated. The other one will be performed with no animation.
     */
    public init(
        onAppear: [TransitionAnimation] = [],
        onDisappear: [TransitionAnimation] = [],
        layout: LayoutTransition = .inherited,
        wrapping element: Element
    ) {
        var onAppear : [TransitionAnimation?] = onAppear
        var onDisappear : [TransitionAnimation?] = onDisappear
        
        let countDifference = abs(onAppear.count - onDisappear.count)
        
        if onAppear.count > onDisappear.count {
            onDisappear.append(contentsOf: Array(repeating: nil, count: countDifference))
        } else if onDisappear.count > onAppear.count {
            onAppear.append(contentsOf: Array(repeating: nil, count: countDifference))
        }
        
        var nested = Transition(
            onAppear: onAppear.popLast()!,
            onDisappear: onDisappear.popLast()!,
            layout: layout,
            wrapping: element
        )
        
        nested.onAppear?.performing = .always
        nested.onDisappear?.performing = .always
        
        while onAppear.isEmpty == false || onDisappear.isEmpty == false {
            nested = Transition(
                onAppear: onAppear.popLast()!,
                onDisappear: onDisappear.popLast()!,
                layout: layout,
                wrapping: nested
            )
            
            nested.onAppear?.performing = .always
            nested.onDisappear?.performing = .always
        }
        
        self = nested
    }

    /**
     Creates a new `Transition` with the provided options.
    
     If you only provide one of `onAppear` or `onDisappear`, only that direction of appearance
     transition will be animated. The other one will be performed with no animation.
     */
    public init(
        onAppear: TransitionAnimation? = nil,
        onDisappear: TransitionAnimation? = nil,
        layout: LayoutTransition = .inherited,
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
        ViewDescription(TransitionContainerView.self) {
            
            $0.builder = { TransitionContainerView(frame: bounds) }
            
            $0.onAppear = onAppear
            $0.onDisappear = onDisappear
            $0.onLayout = onLayout
        }
    }
}


/**
 A view class used to wrap elements that are within a `TransitionContainer`.
 The animations of the `TransitionContainer` are applied to this view.
 
 This is used instead of a plain `UIView` so when examining the view hierarchy,
 there's an indication of where the view is coming from.
 */
final class TransitionContainerView : UIView {
    
    override var bounds: CGRect {
        didSet {
            if self.bounds.size.width > 10000 {
                print(self.frame)
            }
        }
    }
    
    override var frame: CGRect {
        didSet {
            if self.frame.size.width > 10000 {
                print(self.frame)
            }
        }
    }
    
    override var transform: CGAffineTransform {
        didSet {
            if self.frame.size.width > 10000 {
                print(self.frame)
            }
        }
    }
}
