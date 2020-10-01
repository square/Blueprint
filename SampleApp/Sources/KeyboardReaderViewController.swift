//
//  KeyboardReaderViewController.swift
//  SampleApp
//
//  Created by Kyle Van Essen on 9/30/20.
//  Copyright © 2020 Square. All rights reserved.
//

import UIKit
import BlueprintUI
import BlueprintUICommonControls


final class KeyboardReaderViewController : UIViewController
{
    override func loadView() {
        
        let view = BlueprintView()
        
        view.element = self.content()
        
        self.view = view
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Dismiss", style: .plain, target: self, action: #selector(dismissKeyboard))
    }
    
    private func content() -> Element
    {
        KeyboardReader { info in
            Column {
                $0.verticalUnderflow = .justifyToCenter
                
                $0.addFixed(child: TextField(text: "Hello, World!"))
            }
            .map {
                switch info.keyboardFrame {
                case .nonOverlapping:
                    return $0.constrainedTo(height: .absolute(info.size.height))
                    
                case .overlapping(let frame):
                    return $0.constrainedTo(height: .absolute(info.size.height - frame.height))
                }
            }
        }
    }
    
    @objc private func dismissKeyboard() {
        self.view.endEditing(true)
    }
}
