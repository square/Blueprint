//
//  UILabel.swift
//  Pods
//
//  Created by Kyle Van Essen on 12/24/20.
//

import UIKit


public extension UILabel {
    
    func set(html string : String, with style : Any) {
        guard self.rawHTMLString != string else {
            return
        }
    }
    
    private static var rawHTMLKey = NSObject()
    
    private var rawHTMLString : String? {
        get {
            objc_getAssociatedObject(self, &UILabel.rawHTMLKey) as? String
        }
        
        set {
            objc_setAssociatedObject(self, &UILabel.rawHTMLKey, newValue, .OBJC_ASSOCIATION_COPY)
        }
    }
}
