import UIKit


/**
 Defines the animation used when an element is inserted or removed during an update cycle.
 
 You may provide a standard UIKit animation, or an entirely custom animation via the `animationKind` property.
 
 You can control how the animation should react to other parent animations via the `performing` property.
 */
public struct TransitionAnimation {
    
    /**
     The kind of animation:
     - A standard UIView.animate(with...) animation.
     - A `CustomAnimation` that can defer to CoreAnimation, CADisplayLink, etc.
     */
    public var animationKind : AnimationKind
    
    /// When the transition animation should be performed, if nested within other transition animations.
    public var performing : PerformRule
    
    /// Called when the appearance animation is completed.
    public var completion : (Bool) -> ()
    
    //
    // MARK: Initialization
    //
    
    public static func with(
        options : AnimationOptions = .init(),
        animations : AnimatableViewProperties,
        performing : PerformRule = .ifNotNested,
        completion : @escaping (Bool) -> () = { _ in }
    ) -> Self
    {
        return self.init(
            animationKind: .standard(options: options, properties: animations),
            performing: performing
        )
    }
    
    public init(
        animationKind : AnimationKind,
        performing : PerformRule = .ifNotNested,
        completion : @escaping (Bool) -> () = { _ in }
    ) {
        self.animationKind = animationKind
        self.performing = performing
        self.completion = completion
    }
}


extension TransitionAnimation {
    
    /// When the animation should be performed relative to other animations
    /// further up the tree (eg, `TransitionAnimations` for parent elements).
    public enum PerformRule {
        /// The animation will always be performed, even if it is nested in other transition animations.
        case always
        
        /// The animation will only be performed if not nested in other transition animations.
        case ifNotNested
    }
    
    
    /// The kind of animation to perform.
    public enum AnimationKind {
        /**
         A standard UIKit animation (eg, `UIView.animate(with..`) that animates to/from the properties provided by `Properties`.
         
         You can also control the animation options through the `options` parameter,
         which controls the kind of animation (`normal`, `spring`, `keyframe`), the `duration`, `delay`, `curve`, etc.
         */
        case standard(options : AnimationOptions = .init(), properties : AnimatableViewProperties)
        
        /**
         A custom animation which can be backed by CoreAnimation, CADisplayLink, etc.
         
         When performing an animation, Blueprint will call your provided factory to create a new
         `CustomTransitionAnimation` for each animation instance. This allows you to hold onto state
         within your `CustomTransitionAnimation` object to track and manage the animation.
         
         The `CustomTransitionAnimation` object is retained until the completion block passed to it is called.
         */
        case custom(() -> AnyCustomTransitionAnimation)
    }
    
    
    /// If the transition is appearing or disappearing the element.
    public enum Direction : Equatable {
        
        /// The `Element` is being transitioned into place, and will be animated in.
        case appearing
        
        /// The `Element` is being removed from the hierarchy, and will be animated out.
        case disappearing
    }
}


extension TransitionAnimation {

    func animate(
        direction : Direction,
        with view: UIView,
        layoutAttributes: LayoutAttributes,
        completion callerCompletion : @escaping (Bool) -> () = { _ in }
    ) {
        let isAppearing = direction == .appearing
        let currentProperties = AnimatableViewProperties(withPropertiesFrom: view)
        
        let completion : (Bool) -> () = {
            callerCompletion($0)
            self.completion($0)
        }
        
        switch self.animationKind {
        case .standard(let options, let properties):
            
            let finalProperties = isAppearing ? currentProperties : properties
            
            if isAppearing {
                UIView.performWithoutAnimation {
                    properties.apply(to: view)
                }
            }
            
            options.perform(
                animations: {
                    finalProperties.apply(to: view)
                },
                completion: completion
            )
            
        case .custom(let animationFactory):
            let animation = animationFactory()
            
            var calledCompletion : Bool = false
            
            animation.animateAny(
                direction: direction,
                with: view,
                currentProperties: currentProperties,
                completion: {
                    precondition(calledCompletion == false, "CustomAnimation ('\(type(of: animation))') must only call the provided completion block once.")
                    calledCompletion = true
                    
                    defer {
                        // Ensure the animation is retained until the completion block is called.
                        // This allows the animation to maintain any state critical to its execution.
                        withExtendedLifetime(animation) {
                            animation.didEnd()
                        }
                    }
                    
                    completion($0)
                }
            )
        }
    }
}
