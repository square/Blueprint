import UIKit

/// The transition used when a view is inserted or removed during an update cycle.
public struct VisibilityTransition {

    /// The alpha of the view in the hidden state (initial for appearing, final for disappearing).
    public var alpha: CGFloat

    /// The transform of the view in the hidden state (initial for appearing, final for disappearing).
    public var transform: CATransform3D

    /// The animation attributes that will be used to drive the transition.
    public var attributes: AnimationAttributes

    public init(alpha: CGFloat, transform: CATransform3D, attributes: AnimationAttributes = AnimationAttributes()) {
        self.alpha = alpha
        self.transform = transform
        self.attributes = attributes
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
        var attributes = layoutAttributes
        attributes.transform = CATransform3DConcat(attributes.transform, transform)
        attributes.alpha *= alpha
        return attributes
    }
}
