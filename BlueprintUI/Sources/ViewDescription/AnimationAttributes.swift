import UIKit

/// UIView animation configuration values.
public struct AnimationAttributes {

    /// The duration of the animation.
    public var duration: TimeInterval

    /// The timing curve of the animation.
    public var curve: UIView.AnimationCurve

    /// Whether the view supports user interaction during the animation.
    public var allowUserInteraction: Bool

    // Animation attributes with the default values from `.init()`.
    public static let `default`: Self = .init()

    public init(
        duration: TimeInterval = 0.2,
        curve: UIView.AnimationCurve = .easeInOut,
        allowUserInteraction: Bool = true
    ) {
        self.duration = duration
        self.curve = curve
        self.allowUserInteraction = allowUserInteraction
    }

}


extension AnimationAttributes {

    func perform(animations: @escaping () -> Void, completion: @escaping () -> Void) {

        var options: UIView.AnimationOptions = [UIView.AnimationOptions(animationCurve: curve), .beginFromCurrentState]
        if allowUserInteraction {
            options.insert(.allowUserInteraction)
        }

        UIView.animate(
            withDuration: duration,
            delay: 0.0,
            options: options,
            animations: {
                animations()
            }
        ) { _ in
            completion()
        }

    }
}
