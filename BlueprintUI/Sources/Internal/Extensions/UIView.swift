import UIKit


extension UIView {
    
    public final class var isInAnimationBlock: Bool {
        return self.inheritedAnimationDuration > 0
    }
    
}
