import UIKit

extension UIView {
    
    final class var isInAnimationBlock: Bool {
        return self.inheritedAnimationDuration > 0
    }

    func point(insideSubviewsOnly point: CGPoint, with event: UIEvent?) -> Bool {
        
        for subview in self.subviews {
            guard subview.isHidden == false else {
                continue
            }
            
            let point = self.convert(point, to: subview)
            
            if subview.point(inside: point, with: event) {
                return true
            }
        }
        
        return false
    }
}
