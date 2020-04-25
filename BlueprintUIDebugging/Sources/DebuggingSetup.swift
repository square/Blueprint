//
//  DebuggingSetup.swift
//  BlueprintUIDebugging
//
//  Created by Kyle Van Essen on 4/24/20.
//

import UIKit
import BlueprintUI


public final class DebuggingSetup : NSObject, BlueprintUI.DebuggingSetup {
    
    @objc public static func setup() {
        
        DebuggingSupport.viewDescriptionProvider = { other, element, bounds, debugging in
            ViewDescription(DebuggingView.self) {
                $0.builder = {
                    DebuggingView(frame: bounds, containing: other, for: element, debugging: debugging)
                }
                
                $0.contentView = {
                    if let other = other, let contained = $0.containedView {
                        return other.contentView(in: contained)
                    } else {
                        return $0
                    }
                }
                
                $0.apply {
                    guard let other = other, let view = $0.containedView else {
                        return
                    }

                    other.apply(to: view)
                }
            }
        }
    }
}
