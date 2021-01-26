import UIKit

extension UIView.AnimationOptions {

    init(animationCurve: UIView.AnimationCurve) {
        self = UIView.AnimationOptions(rawValue: UInt(animationCurve.rawValue) << 16)
    }
}


extension CALayer {
    
    public func animateAlongsideUIView(_ build : (inout AnimationBuilder) -> ()) {
        
        CATransaction.begin()
        
        var builder = AnimationBuilder()
        build(&builder)
        
        if let key = self.animationKeys()?.first, let animation = self.animation(forKey: key) {

            CATransaction.setAnimationDuration(animation.duration)
            CATransaction.setAnimationTimingFunction(animation.timingFunction)
            
            
        } else {
            CATransaction.disableActions()
        }
        
        CATransaction.commit()
    }
    
    public struct AnimationBuilder {
        
        public func addAnimation<LayerType:CALayer, Value>(
            for keyPath : String,
            with value : Value, 
            on layer : LayerType
        ) {
            let animation = CABasicAnimation(keyPath: keyPath)
            
            layer.add(animation, forKey: keyPath)
            layer.setValue(value, forKey: keyPath)
        }
        
    }
}
