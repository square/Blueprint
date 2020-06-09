//
//  SplitViewController.swift
//  SampleApp
//
//  Created by Kyle Van Essen on 6/5/20.
//  Copyright © 2020 Square. All rights reserved.
//

import UIKit
import BlueprintUI


final class SplitViewController : UIViewController {
    let blueprintView : BlueprintView = BlueprintView()
    
    override func loadView() {
        self.view = self.blueprintView
        
        self.blueprintView.element = self.element
    }
    
    var element : Element {
        Row { row in
            row.verticalAlignment = .fill
            row.horizontalUnderflow = .growProportionally
            
            
        }
    }
}
