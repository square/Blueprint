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
    let blueprintView = BlueprintView()
    
    override func loadView()
    {
        self.view = self.blueprintView
        
        self.blueprintView.element = self.element
        
        self.view.backgroundColor = .init(white: 0.9, alpha: 1.0)
    }
    
    var element : Element {
        let list = Column { column in 
            column.minimumVerticalSpacing = 20.0
            column.horizontalAlignment = .fill
            
            for (index, demo) in self.demos.enumerated() {
                
                var container = TransitionContainer(wrapping: demo)
                container.appearingTransition = VisibilityTransition.slideIn(after: TimeInterval(0.5 + TimeInterval(index) * 0.2), for: 0.25)
                                
                column.add(child: container)
            }
        }
        
        var scrollView = ScrollView(
            wrapping: Inset(
                uniformInset: 40.0,
                wrapping: Aligned(
                    vertically: .top,
                    horizontally: .center,
                    wrapping: ConstrainedSize(
                        width: .atMost(400.0),
                        wrapping: ConstrainedSize(
                            width: .atLeast(300),
                            wrapping: list
                        )
                    )
                )
            )
        )
        
        scrollView.contentSize = .fittingHeight
        
        return scrollView
    }
    
    fileprivate var demos : [DemoItem] {
        return [
            DemoItem(title: "People", onTap: {
                self.navigationController?.pushViewController(ViewController(), animated: true)
            }),
            DemoItem(title: "Loyalty Screen", onTap: {
                self.navigationController?.pushViewController(ExampleLoyaltyViewController(), animated: true)
            }),
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


fileprivate extension VisibilityTransition
{
    static func slideIn(after delay : TimeInterval, for duration : TimeInterval) -> VisibilityTransition
    {
        VisibilityTransition(
            alpha: 0.0,
            transform: CATransform3DMakeTranslation(0.0, -50.0, 0),
            attributes: AnimationAttributes(
                delay: delay,
                duration: duration,
                curve: .easeOut,
                allowUserInteraction: false
            )
        )
    }
}
