import UIKit

extension UIView.AnimationOptions {

    init(animationCurve: UIView.AnimationCurve) {
        self = UIView.AnimationOptions(rawValue: UInt(animationCurve.rawValue) << 16)
    }

}
