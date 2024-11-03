import UIKit

/// View which does not personally receive touches but allows its subviews to receive touches.
@_spi(BlueprintPassthroughView) public final class PassthroughView: UIView {
    /// This is an optimization to prevent unnecessary drawing of this view,
    /// since `CATransformLayer` doesn't draw its own contents, only child layers.
    public override class var layerClass: AnyClass {
        CATransformLayer.self
    }

    public var passThroughTouches: Bool = true

    /// Ignore any touches on this view and (pass through) by returning nil if the default `hitTest` implementation returns this view.
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)

        if passThroughTouches {
            return result == self ? nil : result
        } else {
            return result
        }
    }
}
