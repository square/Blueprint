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
        _ animations : AnimatableViewProperties,
        options : AnimationOptions = .init(),
        performing : PerformRule = .ifNotNested,
        completion : @escaping (Bool) -> () = { _ in }
    ) -> Self
    {
        Self(
            animationKind: .standard(options: options, properties: animations),
            performing: performing,
            completion: completion
        )
    }
    
    public static func custom(
        _ custom : @escaping @autoclosure () -> AnyCustomTransitionAnimation,
        performing : PerformRule = .ifNotNested,
        completion : @escaping (Bool) -> () = { _ in }
    ) -> Self
    {
        Self(
            animationKind: .custom(custom),
            performing: performing,
            completion: completion
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
    
    /// Controls when/if transition animations should be performed depending on
    /// if the appearing element is contained within other appearing parent elements
    /// further up the element tree during the current update cycle.
    public enum PerformRule {
        /// The animation will **always** be performed, even if it is nested in
        /// other transition animations during the current update cycle.
        /// You probably do not want this option unless you're implementing a very specific case.
        case always
        
        /**
         The animation will only be performed if **not** nested in other parent transition animations during the
         current update.
         
         This is probably the rule you want to use, unless implementing a very specific case.
         
         Example
         ---------
         Consider the below example of Element A and Element B, where B is nested inside A.
         
         If A and B both have animation transitions, and appear at the same time, only A's transition
         will be performed – B will be animated within A's transition.
         
         However, if A is already visible, and then B is added later on, B's animation transition will be
         performed as normal, because it is not nested.
         
         ```
         Element A
         +---------------------+
         | Element B           |
         | +-----------------+ |
         | |                 | |
         | |                 | |
         | +-----------------+ |
         +---------------------+
         ```
         */
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
        let currentProperties = AnimatableViewProperties(withPropertiesFrom: view)
        
        let completion : (Bool) -> () = {
            callerCompletion($0)
            self.completion($0)
        }
        
        switch self.animationKind {
        case .standard(let options, let properties):
            
            let isAppearing = direction == .appearing
            
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
    
    func skipAnimation(
        direction : Direction,
        with view: UIView,
        layoutAttributes: LayoutAttributes,
        completion callerCompletion : @escaping (Bool) -> () = { _ in }
    ) {
        let currentProperties = AnimatableViewProperties(withPropertiesFrom: view)
        
        let completion : (Bool) -> () = {
            callerCompletion($0)
            self.completion($0)
        }
        
        switch self.animationKind {
        case .standard(_, let properties):
            
            let isAppearing = direction == .appearing
            let finalProperties = isAppearing ? currentProperties : properties
                        
            finalProperties.apply(to: view)
            
            completion(true)
            
        case .custom(let animationFactory):
            let animation = animationFactory()

            animation.skipAnimationAny(
                direction: direction,
                with: view,
                currentProperties: currentProperties
            )
            
            completion(true)
        }
    }
}
