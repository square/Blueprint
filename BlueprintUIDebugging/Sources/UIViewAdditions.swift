//
//  UIViewAdditions.swift
//  BlueprintUIDebugging
//
//  Created by Kyle Van Essen on 4/24/20.
//

import UIKit


extension UIView {
    func recurse(with block : (UIView) -> ()) {
        block(self)
        
        for view in self.subviews {
            view.recurse(with: block)
        }
    }
    
    func superview(passing : (UIView) -> Bool) -> UIView? {
        
        var current = self.superview
        
        while let superview = current {
            if passing(superview) {
                return superview
            }
            
            current = superview.superview
        }
        
        return nil
    }
    
    func views(at point : CGPoint, below superview : (UIView) -> Bool) -> [UIView] {
        var views = [UIView]()
        
        let startingView = self.superview(passing: superview) ?? self
        
        startingView.recurse { view in
            let isPointInside = view.point(inside: self.convert(point, to: view), with: nil)
            
            let isSmallerThanView = self.frame.contains(view.convert(view.bounds, to: self))
            
            if isPointInside && isSmallerThanView {
                views.append(view)
            }
        }
        
        return views
    }
}
