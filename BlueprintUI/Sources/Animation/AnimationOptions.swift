import UIKit


/**
 Configures the animation kind and animation options for a UIView-backed animation.
 */
public struct AnimationOptions {

    /// The type of animation used: Regular, spring, or keyframe, plus the animation options
    /// associated with each animation type.
    public var animationKind : AnimationKind
    
    /// How long to delay the start of the animation.
    public var delay : TimeInterval
    
    /// The duration of the animation.
    public var duration: TimeInterval

    /// The timing curve of the animation.
    public var curve: UIView.AnimationCurve

    /// Whether the view supports user interaction during the animation.
    public var allowUserInteraction: Bool

    public init(
        animationKind : AnimationKind = .regular(),
        delay : TimeInterval = 0.0,
        duration: TimeInterval = 0.2,
        curve: UIView.AnimationCurve = .easeInOut,
        allowUserInteraction: Bool = true,
        configure : (inout AnimationOptions) -> () = { _ in }
    ) {
        self.animationKind = animationKind
        self.delay = delay
        self.duration = duration
        self.curve = curve
        self.allowUserInteraction = allowUserInteraction
        
        configure(&self)
    }
}


extension AnimationOptions {
    
    public enum AnimationKind {
        /**
         A  "normal" UIView animation, eg:
         
         ```
         UIView.animate(
             withDuration: ...,
             delay: ...,
             options: options,
             animations: ...,
             completion: ...
         )
         ```
         
         The provided animation options are included in the options passed to the animate method.
         */
        case regular(options : UIView.AnimationOptions = .init())
        
        /**
         A spring-driven UIView animation, eg:
         
         ```
         UIView.animate(
             withDuration: ...,
             delay: ...,
             usingSpringWithDamping: dampingRatio,
             initialSpringVelocity: velocity,
             options: options,
             animations: ...,
             completion: ...
         )
         ```
         
         The provided animation options are included in the options passed to the animate method.
         */
        case spring(dampingRatio : CGFloat, velocity: CGFloat, options : UIView.AnimationOptions = .init())
        
        /**
         A keyframe UIView animation, eg:
         
         ```
         UIView.animateKeyframes(
             withDuration: ...,
             delay: ...,
             options: options,
             animations: ...,
             completion: ...
         )
         ```
         
         The provided animation options are included in the options passed to the animate method.
         */
        case keyframe(options : UIView.KeyframeAnimationOptions = .init())
    }
}


extension AnimationOptions {

    func perform(animations: @escaping () -> Void, completion: @escaping (Bool) -> () = { _ in }) {
        
        // Default animation options based on our configuration.
        
        var options: UIView.AnimationOptions = [
            UIView.AnimationOptions(animationCurve: curve),
            .beginFromCurrentState
        ]
        
        var keyframeOptions : UIView.KeyframeAnimationOptions = [
            .beginFromCurrentState
        ]
        
        if allowUserInteraction {
            options.insert(.allowUserInteraction)
            keyframeOptions.insert(.allowUserInteraction)
        }
        
        switch self.animationKind {
        case .regular(let additionalOptions):
                        
            UIView.animate(
                withDuration: duration,
                delay: delay,
                options: options.union(additionalOptions),
                animations: animations,
                completion: completion
            )
            
        case .spring(let dampingRatio, let velocity, let additionalOptions):
                        
            UIView.animate(
                withDuration: duration,
                delay: delay,
                usingSpringWithDamping: dampingRatio,
                initialSpringVelocity: velocity,
                options: options.union(additionalOptions),
                animations: animations,
                completion: completion
            )
            
        case .keyframe(let additionalOptions):
            
            UIView.animateKeyframes(
                withDuration: duration,
                delay: delay,
                options: keyframeOptions.union(additionalOptions),
                animations: animations,
                completion: completion
            )
        }
    }
}
