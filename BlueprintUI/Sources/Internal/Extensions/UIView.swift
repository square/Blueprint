import UIKit

extension UIView {
    
    final class var isInAnimationBlock: Bool {
        return self.inheritedAnimationDuration > 0
    }
    
}
