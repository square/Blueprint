//
//  DemoListScreen.swift
//  SampleApp
//
//  Created by Kyle Van Essen on 1/16/20.
//  Copyright © 2020 Square. All rights reserved.
//

import UIKit
import BlueprintUI
import BlueprintUICommonControls


final class DemoListViewController : UIViewController
{
    override func loadView()
    {
        let blueprintView = BlueprintView(element: self.element, animateInitialLayout: true)
        
        self.view = blueprintView
                
        self.view.backgroundColor = .init(white: 0.9, alpha: 1.0)
    }
    
    var element : Element {
        let list = Column { column in 
            column.minimumVerticalSpacing = 20.0
            column.horizontalAlignment = .fill
            
            for (index, demo) in self.demos.enumerated() {
                column.add(child: AppearanceTransition(
                    onAppear: .slideIn(from: -50.0, after: TimeInterval(0.5 + TimeInterval(index) * 0.2), for: 0.25),
                    wrapping: demo
                ))
            }
        }
        
        return list
            .constrainedTo(width: .atLeast(300))
            .constrainedTo(width: .atMost(400))
            .aligned(vertically: .top, horizontally: .center)
            .inset(uniform: 40.0)
            .scrollable(.fittingHeight)
    }
    
    fileprivate var demos : [DemoItem] {
        return [
            DemoItem(title: "People", onTap: {
                self.navigationController?.pushViewController(PostsViewController(), animated: true)
            }),
            DemoItem(title: "Loyalty Screen", onTap: {
                self.navigationController?.pushViewController(ExampleLoyaltyViewController(), animated: true)
            }),
            DemoItem(title: "Custom Animations", onTap: {
                self.navigationController?.pushViewController(StatusProgressViewController(), animated: true)
            }),
//            DemoItem(title: "Text Field Layout", onTap: {
//                self.navigationController?.pushViewController(TextFieldViewController(), animated: true)
//            }),
        ]
    }
}

fileprivate struct DemoItem : ProxyElement
{
    var title : String
    var onTap : () -> ()
    
    var elementRepresentation: Element {
        let label = Label(text: self.title) { label in
            label.font = .systemFont(ofSize: 18.0, weight: .semibold)
        }
        
        var box = Box(backgroundColor: .white, cornerStyle: .rounded(radius: 20.0), wrapping: Inset(uniformInset: 20.0, wrapping: label))
        
        box.shadowStyle = .simple(radius: 6.0, opacity: 0.2, offset: .init(width: 0, height: 3.0), color: .black)
        
        return Button(onTap: self.onTap, wrapping: box)
    }
}

