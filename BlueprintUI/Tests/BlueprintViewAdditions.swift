//
//  BlueprintViewAdditions.swift
//  BlueprintUI-Unit-Tests
//
//  Created by Kyle Van Essen on 2/21/20.
//

import UIKit

@testable import BlueprintUI

/**
 Testing additions to help verify native view construction and management.
 */
extension BlueprintView
{
    internal var rootNativeElementViews : [UIView] {
        
        /**
         Note: Assumes the `BlueprintView` has exactly one
         subview (root view-backed element provided by the view itself),
         which then contains all root view-backed elements. Eg:
         
         ```
           BlueprintView
               UIView
                   ElementView1
                   ElementView2
                   ElementView3
                   ...
         ```
         */
        
        self.subviews.first?.subviews ?? []
    }
}
