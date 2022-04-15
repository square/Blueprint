import UIKit

/// View which does not personally receive touches but allows its subviews to receive touches.
final class PassthroughView: UIView {
    /// This is an optimization to prevent unnecessary drawing of this view,
    /// since `CATransformLayer` doesn't draw its own contents, only child layers.
    override class var layerClass: AnyClass {
        CATransformLayer.self
    }

    /// Ignore any touches on this view and (pass through) by returning nil if the
    /// default `hitTest` implementation returns this view.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        return result == self ? nil : result
    }
}
