import UIKit

///
/// A ``UIView`` which does not  receive touches but allows its subviews to receive touches.
///
/// This is useful when you would like to implement a view-backed element which needs to
/// be hosted in the view hierarchy, but otherwise should not interfere with touches which are
/// meant for views lower in the hierarchy. Subviews will continue to receive touches as normal.
///
final class TouchPassthroughView: UIView {
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self ? nil : view
    }
}
