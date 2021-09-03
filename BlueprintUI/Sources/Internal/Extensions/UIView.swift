import UIKit

extension UIView {

    final class var isInAnimationBlock: Bool {
        inheritedAnimationDuration > 0
    }

}
