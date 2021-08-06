import UIKit

extension UIView {

    final class var isInAnimationBlock: Bool {
        return inheritedAnimationDuration > 0
    }

}
