import UIKit

/// The transition used when a view is inserted or removed during an update cycle.
public struct VisibilityTransition {
    public typealias Transform = (ElementDimensions) -> CATransform3D

    /// The alpha of the view in the hidden state (initial for appearing, final for disappearing).
    public var alpha: CGFloat

    /// The transform of the view in the hidden state (initial for appearing, final for disappearing).
    public var transform: Transform

    /// The animation attributes that will be used to drive the transition.
    public var attributes: AnimationAttributes

    public init(
        alpha: CGFloat,
        transform: @escaping Transform,
        attributes: AnimationAttributes = .default
    ) {
        self.alpha = alpha
        self.transform = transform
        self.attributes = attributes
    }

    public init(
        alpha: CGFloat,
        transform: CATransform3D,
        attributes: AnimationAttributes = .default
    ) {
        self.init(alpha: alpha, transform: { _ in transform }, attributes: attributes)
    }

    /// Returns a `VisibilityTransition` that scales in and out.
    public static var scale: VisibilityTransition {
        VisibilityTransition(
            alpha: 1.0,
            transform: CATransform3DMakeScale(0.01, 0.01, 0.01)
        )
    }

    /// Returns a `VisibilityTransition` that fades in and out.
    public static var fade: VisibilityTransition {
        VisibilityTransition(
            alpha: 0.0,
            transform: CATransform3DIdentity
        )
    }

    /// Returns a `VisibilityTransition` that simultaneously scales and fades in and out.
    public static var scaleAndFade: VisibilityTransition {
        VisibilityTransition(
            alpha: 0.0,
            transform: CATransform3DMakeScale(0.01, 0.01, 0.01)
        )
    }

    public static func slide(
        direction: TranslationDirection,
        coefficient: CGFloat
    ) -> VisibilityTransition {
        VisibilityTransition(alpha: 1.0) { dimensions in
            CATransform3DMakeAffineTransform(
                direction.affineTransform(
                    x: dimensions.width,
                    y: dimensions.height,
                    coefficient: coefficient
                )
            )
        }
    }
}

extension VisibilityTransition {
    public struct TranslationDirection: Equatable {
        public static let right = Self(angle: 0)
        public static let up = Self(angle: .pi * 0.5)
        public static let left = Self(angle: .pi)
        public static let down = Self(angle: .pi * 1.5)

        public var angle: CGFloat

        public init(angle: CGFloat) {
            self.angle = angle
        }

        public func affineTransform(x: CGFloat, y: CGFloat, coefficient: CGFloat) -> CGAffineTransform {
            switch self {
            case .right:
                return CGAffineTransform(translationX: x * coefficient, y: 0)
            case .up:
                return CGAffineTransform(translationX: 0, y: -y * coefficient)
            case .left:
                return CGAffineTransform(translationX: -x * coefficient, y: 0)
            case .down:
                return CGAffineTransform(translationX: 0, y: y * coefficient)
            default:
                // these results are not great, the interpolation doesn't line up with expected angle
                let dx = cos(angle) * x * coefficient
                let dy = sin(angle) * y * coefficient
                return CGAffineTransform(translationX: dx, y: -dy)
            }
        }
    }
}


extension VisibilityTransition {

    func performAppearing(view: UIView, layoutAttributes: LayoutAttributes, completion: @escaping () -> Void) {

        UIView.performWithoutAnimation {
            self.getInvisibleAttributesFor(layoutAttributes: layoutAttributes).apply(to: view)
        }

        attributes.perform(
            animations: { layoutAttributes.apply(to: view) },
            completion: completion
        )


    }

    func performDisappearing(view: UIView, layoutAttributes: LayoutAttributes, completion: @escaping () -> Void) {

        attributes.perform(
            animations: {
                self.getInvisibleAttributesFor(layoutAttributes: layoutAttributes).apply(to: view)
            },
            completion: completion
        )

    }

    private func getInvisibleAttributesFor(layoutAttributes: LayoutAttributes) -> LayoutAttributes {
        let dimensions = ElementDimensions(size: layoutAttributes.bounds.size)
        let resolvedTransform = transform(dimensions)

        var attributes = layoutAttributes

        attributes.transform = CATransform3DConcat(attributes.transform, resolvedTransform)
        attributes.alpha *= alpha

        return attributes
    }
}
