import UIKit

/// UIView animation configuration values.
public struct AnimationAttributes {

    var animation: Animation

    /// Whether the view supports user interaction during the animation.
    public var allowUserInteraction: Bool

    // Animation attributes with the default values from `.init()`.
    public static let `default`: Self = .init()

    // Creates an animation with a duration and a UIView animation curve.
    public init(
        duration: TimeInterval = 0.2,
        curve: UIView.AnimationCurve = .easeInOut,
        allowUserInteraction: Bool = true
    ) {
        self.init(
            animation: .curve(curve, duration: duration),
            allowUserInteraction: allowUserInteraction
        )
    }

    init(animation: Animation, allowUserInteraction: Bool = true) {
        self.animation = animation
        self.allowUserInteraction = allowUserInteraction
    }

    /// An animation that uses in the built-in UIView animation curves.
    public static func curve(_ curve: UIView.AnimationCurve, duration: TimeInterval, allowUserInteraction: Bool = true) -> Self {
        self.init(animation: .curve(curve, duration: duration), allowUserInteraction: allowUserInteraction)
    }

    /// An animation whose easing curve is determined by two control points.
    public static func cubicBezier(
        controlPoint1: CGPoint,
        controlPoint2: CGPoint,
        duration: TimeInterval,
        allowsUserInteraction: Bool = true
    ) -> Self {
        self.init(
            animation: .cubicBezier(controlPoint1: controlPoint1, controlPoint2: controlPoint2, duration: duration),
            allowUserInteraction: allowsUserInteraction
        )
    }

    /// A spring animation based on a damping ratio and initial velocity.
    public static func dampenedSpring(
        dampingRatio: CGFloat = 1,
        initialVelocity: CGVector = .zero,
        duration: TimeInterval,
        allowUserInteraction: Bool = true
    ) -> Self {
        self.init(
            animation: .dampenedSpring(dampingRatio: dampingRatio, initialVelocity: initialVelocity, duration: duration),
            allowUserInteraction: allowUserInteraction
        )
    }

    /// A spring animation based off the physics of an object with mass, a spring stiffness and damping,
    /// and initial velocity. The duration of the animation is determined by the physics of the spring.
    ///
    /// The default arguments for each parameter match those of the system spring animation used for transitions
    /// such as modal presentation, navigation controller push/pop, and keyboard animations. You can match that
    /// animation with `.spring()`.
    public static func spring(
        mass: CGFloat = 3,
        stiffness: CGFloat = 1000,
        damping: CGFloat = 500,
        initialVelocity: CGVector = .zero,
        allowsUserInteraction: Bool = true
    ) -> Self {
        self.init(
            animation: .spring(mass: mass, stiffness: stiffness, damping: damping, initialVelocity: initialVelocity),
            allowUserInteraction: allowsUserInteraction
        )
    }
}


extension AnimationAttributes {

    func perform(animations: @escaping () -> Void, completion: @escaping () -> Void) {
        let animator = UIViewPropertyAnimator(animation: animation)
        animator.isUserInteractionEnabled = allowUserInteraction
        animator.addAnimations(animations)
        animator.addCompletion { _ in completion() }
        animator.startAnimation()
    }
}

extension AnimationAttributes {
    enum Animation: Equatable {
        case curve(UIView.AnimationCurve, duration: TimeInterval)

        case cubicBezier(controlPoint1: CGPoint, controlPoint2: CGPoint, duration: TimeInterval)

        case dampenedSpring(
            dampingRatio: CGFloat = 1,
            initialVelocity: CGVector = .zero,
            duration: TimeInterval
        )

        case spring(
            mass: CGFloat = 3,
            stiffness: CGFloat = 1000,
            damping: CGFloat = 500,
            initialVelocity: CGVector = .zero
        )
    }
}

extension UIViewPropertyAnimator {
    convenience init(animation: AnimationAttributes.Animation) {
        switch animation {
        case .curve(let curve, let duration):
            self.init(duration: duration, curve: curve)

        case .cubicBezier(let controlPoint1, let controlPoint2, let duration):
            self.init(
                duration: duration,
                controlPoint1: controlPoint1,
                controlPoint2: controlPoint2
            )

        case .dampenedSpring(let dampingRatio, let initialVelocity, let duration):
            let parameters = UISpringTimingParameters(
                dampingRatio: dampingRatio,
                initialVelocity: initialVelocity
            )
            self.init(duration: duration, timingParameters: parameters)

        case .spring(let mass, let stiffness, let damping, let initialVelocity):
            let parameters = UISpringTimingParameters(
                mass: mass,
                stiffness: stiffness,
                damping: damping,
                initialVelocity: initialVelocity
            )
            // The duration is not needed, so any value works.
            self.init(duration: 0, timingParameters: parameters)
        }
    }
}
