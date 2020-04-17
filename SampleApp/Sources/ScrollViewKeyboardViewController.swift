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
        var scrollView = ScrollView(wrapping: Column {
            $0.horizontalAlignment = .fill
            
            for _ in 1...20 {
                let textField = TextField(text: "Hello")
                
                let box = Box(
                    backgroundColor: .init(white: 0.95, alpha: 1.0),
                    cornerStyle: .square,
                    wrapping: Inset(uniformInset: 20.0, wrapping: textField)
                )

                $0.add(child: box)
            }
        })
        
        //scrollView.contentInset.bottom = 20.0
        
        scrollView.keyboardAdjustmentMode = .adjustsWhenVisible
        
        return scrollView
    }
}
