//
//  ScrollViewKeyboardViewController.swift
//  SampleApp
//
//  Created by Kyle Van Essen on 3/22/20.
//  Copyright © 2020 Square. All rights reserved.
//

import UIKit
import BlueprintUI
import BlueprintUICommonControls


final class ScrollViewKeyboardViewController : UIViewController
{
    override func loadView() {
        
        let view = BlueprintView()
        
        view.element = self.content()
        
        self.view = view
    }
    
    private func content() -> Element
    {
        Column {
            $0.horizontalAlignment = .fill
            
            $0 += (1...20).map { _ in
                .fixed {
                    TextField(text: "Hello, World")
                        .inset(uniform: 20.0)
                        .box(background: .init(white: 0.95, alpha: 1.0))
                }
            }
        }.scrollable {
            $0.keyboardAdjustmentMode = .adjustsWhenVisible
        }
    }
}
