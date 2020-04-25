//
//  UIViewControllerAdditions.swift
//  BlueprintUIDebugging
//
//  Created by Kyle Van Essen on 4/24/20.
//

import UIKit


extension UIViewController {
    var viewControllerToPresentOn : UIViewController {
        var toPresentOn : UIViewController = self
        
        repeat {
            if let presented = toPresentOn.presentedViewController {
                toPresentOn = presented
            } else {
                break
            }
        } while true

        return toPresentOn
    }
}
