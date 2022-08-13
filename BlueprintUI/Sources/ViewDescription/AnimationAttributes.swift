import UIKit

/// UIView animation configuration values.
public struct AnimationAttributes {

    public var animation: Animation

    /// Whether the view supports user interaction during the animation.
    public var allowUserInteraction: Bool

    // Animation attributes with the default values from `.init()`.
    public static let `default`: Self = .init()

    public init(
        duration: TimeInterval = 0.2,
        curve: UIView.AnimationCurve = .easeInOut,
        allowUserInteraction: Bool = true
    ) {
        self.init(
            animation: .curve(.init(curve), duration: duration),
            allowUserInteraction: allowUserInteraction
        )
    }

    public init(animation: Animation, allowUserInteraction: Bool = true) {
        self.animation = animation
        self.allowUserInteraction = allowUserInteraction
    }
}


extension AnimationAttributes {

    func perform(animations: @escaping () -> Void, completion: @escaping () -> Void) {
        let animator = UIViewPropertyAnimator(animation: animation)
        // TODO: beginFromCurrentState?
        animator.isUserInteractionEnabled = allowUserInteraction
        animator.addAnimations(animations)
        animator.addCompletion { _ in completion() }
        animator.startAnimation()
    }
}

extension AnimationAttributes {
    /// Describes the timing function for a UI animation, also known as the easing.
    public enum Animation: Equatable {
        /// An animation based off a system-defined curve.
        case curve(SystemCurve, duration: TimeInterval)

        /// An animation whose easing curve is determined by two control points.
        case cubicBezier(controlPoint1: CGPoint, controlPoint2: CGPoint, duration: TimeInterval)

        /// A spring animation based on a damping ratio and initial velocity.
        case dampenedSpring(
            dampingRatio: CGFloat = 1,
            initialVelocity: CGVector = .zero,
            duration: TimeInterval
        )

        /// A spring animation based off the physics of an object with mass, a spring stiffness and damping,
        /// and initial velocity. The duration of the animation is determined by the physics of the spring.
        ///
        /// The default arguments for each parameter match those of the system spring animation used for transitions
        /// such as modal presentation, navigation controller push/pop, and keyboard animations. You can match that
        /// animation with `.spring()`.
        case spring(
            mass: CGFloat = 3,
            stiffness: CGFloat = 1000,
            damping: CGFloat = 500,
            initialVelocity: CGVector = .zero
        )
    }
}

extension AnimationAttributes.Animation {
    // TODO: need this? we only support UIKit

    /// Constants corresponding to system-defined animation curves, when available.
    ///
    /// The exact timing values will vary depending on the animation implementation. In UIKit,
    /// these correspond the cases of `UIView.AnimationCurve`.
    public enum SystemCurve: Equatable {
        case easeInOut
        case easeIn
        case easeOut
        case linear

        public init(_ curve: UIView.AnimationCurve) {
            switch curve {
            case .easeInOut:
                self = .easeInOut
            case .easeIn:
                self = .easeIn
            case .easeOut:
                self = .easeOut
            case .linear:
                self = .linear
            @unknown default:
                fatalError("Unknown UIView.AnimationCurve value \(curve.rawValue)")
            }
        }
    }
}

extension UIViewPropertyAnimator {
    convenience init(animation: AnimationAttributes.Animation) {
        switch animation {
        case .curve(let curve, let duration):
            self.init(duration: duration, curve: .init(curve))

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
            self.init(duration: 0, timingParameters: parameters)
        }
    }
}

extension UIView.AnimationCurve {
    init(_ curve: AnimationAttributes.Animation.SystemCurve) {
        switch curve {
        case .easeInOut:
            self = .easeInOut
        case .easeIn:
            self = .easeIn
        case .easeOut:
            self = .easeOut
        case .linear:
            self = .linear
        }
    }
}
