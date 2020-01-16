import UIKit

/// UIView animation configuration values.
public struct AnimationAttributes {

    public var delay : TimeInterval
    
    /// The duration of the animation.
    public var duration: TimeInterval

    /// The timing curve of the animation.
    public var curve: UIView.AnimationCurve

    /// Whether the view supports user interaction during the animation.
    public var allowUserInteraction: Bool

    public init(delay : TimeInterval = 0.0, duration: TimeInterval = 0.2, curve: UIView.AnimationCurve = .easeInOut, allowUserInteraction: Bool = true) {
        self.delay = delay
        self.duration = duration
        self.curve = curve
        self.allowUserInteraction = allowUserInteraction
    }

}


extension AnimationAttributes {

    func perform(animations: @escaping () -> Void, completion: @escaping ()->Void) {

        var options: UIView.AnimationOptions = [UIView.AnimationOptions(animationCurve: curve), .beginFromCurrentState]
        if allowUserInteraction {
            options.insert(.allowUserInteraction)
        }

        UIView.animate(
            withDuration: duration,
            delay: delay,
            options: options,
            animations: {
                animations()
            }) { _ in
                completion()
            }

    }
}
