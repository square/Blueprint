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
        ScrollView(wrapping: Column {
            $0.horizontalAlignment = .fill
            
            $0 += (1...20).map { _ in
                TextField(text: "Hello")
                    .inset(uniform: 20.0)
                    .box(backgroundColor: .init(white: 0.95, alpha: 1.0))
            }
        }) {
            $0.keyboardAdjustmentMode = .adjustsWhenVisible
        }
    }
}
