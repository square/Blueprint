import UIKit

extension UIView {
    
    /// `true` if inside a `UIView` animation block, `false` otherwise.
    final class var isInAnimationBlock: Bool {
        return self.inheritedAnimationDuration > 0
    }

    /// An implementation of `point(inside:with:)` that only hit tests on visible subviews,
    /// bypassing hit testing on the view instance itself, making it transparent to the UIKit hit-testing system.
    ///
    /// If you are implementing a custom `UIView` or `Element` that manages displaying its own `Element`,
    /// you will likely want to override `point(inside:with:)` and call this method – this ensures that
    /// your view won't occlude touches to views lower in the view hierarchy.
    func point(insideSubviewsOnly point: CGPoint, with event: UIEvent?) -> Bool {
        
        self.subviews.first { subview in
            guard subview.isHidden == false && subview.alpha > 0 else {
                return false
            }
            
            return subview.point(
                inside: self.convert(point, to: subview),
                with: event
            )
        } != nil
    }
}
