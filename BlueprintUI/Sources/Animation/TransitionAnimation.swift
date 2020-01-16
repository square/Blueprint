import UIKit


/// The transition used when a view is inserted or removed during an update cycle.
public struct TransitionAnimation {
    
    /**
     The kind of animation:
     - A standard UIView.animate(with...) animation.
     - A `CustomAnimation` that can defer to CoreAnimation, CADisplayLink, etc.
     */
    public var kind : Kind
    
    /// When the transition animation should be performed, if nested within other transition animations.
    public var performing : PerformRule
    
    /// Called when the appearance animation is completed.
    public var completion : (Bool) -> ()
    
    public static func with(
        options : AnimationOptions = .init(),
        animations : AnimatableViewProperties,
        performing : PerformRule = .ifNotNested,
        completion : @escaping (Bool) -> () = { _ in }
    ) -> Self
    {
        return self.init(
            kind: .standard(options: options, properties: animations),
            performing: performing
        )
    }
    
    public init(
        kind : Kind,
        performing : PerformRule = .ifNotNested,
        completion : @escaping (Bool) -> () = { _ in }
    ) {
        self.kind = kind
        self.performing = performing
        self.completion = completion
    }

    /// Returns a `VisibilityTransition` that scales in and out.
    public static var scale: Self {
        return .with(
            animations: AnimatableViewProperties(transform: .init(scaleX: 0.01, y: 0.01))
        )
    }

    /// Returns a `VisibilityTransition` that fades in and out.
    public static var fade: Self {
        return .with(
            animations: AnimatableViewProperties(alpha: 0.0)
        )
    }

    /// Returns a `VisibilityTransition` that simultaneously scales and fades in and out.
    public static var scaleAndFade: Self {
        return .with(
            animations: AnimatableViewProperties(
                alpha: 0.0,
                transform: .init(scaleX: 0.01, y: 0.01)
            )
        )
    }
    
    /**
     Returns a `VisibilityTransition` that simultaneously slides content in from
     the given direction after given delay, alongside a simultaneous fade animation.
     
     The animation is a spring animation.
     
     The default options provide a slide animation that drops in from the top over 0.5 seconds.
     
     Provide a negative `distance` to slide in from the top, or a positive `distance` to slide in
     from the bottom.
     */
    public static func slideIn(
        from distance : CGFloat = -50.0,
        after delay : TimeInterval = 0.0,
        for duration : TimeInterval = 0.5
    ) -> Self {
        
        return TransitionAnimation.with(
            options: AnimationOptions(
                animationKind: .spring(dampingRatio: 0.5, velocity: 0.3),
                delay: delay,
                duration: duration,
                curve: .easeOut
            ),
            animations: AnimatableViewProperties(
                alpha: 0.0,
                transform: CGAffineTransform(translationX: 0.0, y: distance)
            )
        )
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
    public enum Kind {
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
        
        switch self.kind {
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
