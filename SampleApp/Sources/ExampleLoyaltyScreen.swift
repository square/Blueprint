//
//  ExampleLoyaltyScreen.swift
//  SampleApp
//
//  Created by Kyle Van Essen on 1/16/20.
//  Copyright © 2020 Square. All rights reserved.
//

import UIKit
import BlueprintUI
import BlueprintUICommonControls


final class ExampleLoyaltyViewController : UIViewController
{
    let blueprintView = BlueprintView()
    
    override func loadView()
    {
        self.view = self.blueprintView
    }
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
        
        blueprintView.setElement(animated: true, element: Screen())
    }
}


fileprivate struct Screen : ProxyElement
{
    var elementRepresentation: Element {
        return Inset(top: 150.0, bottom: 0.0, left: 100.0, right: 100.0, wrapping: self.screenContent)
    }
    
    var screenContent : Element {
        return Row { row in
            row.horizontalUnderflow = .growProportionally
            row.verticalAlignment = .leading
            
            row.add(child: self.leftInfo)
            
            row.add(child: self.rightInput)
        }
    }
    
    var leftInfo : Element {
        return ConstrainedSize(width: .atLeast(500.0), height: .unconstrained, wrapping: Column { column in
            column.verticalUnderflow = .growProportionally
            column.horizontalAlignment = .fill
            column.minimumVerticalSpacing = 20.0
            
            var titleLabel = TransitionContainer(wrapping: Label(text: "Get 10 points for your purchase today.") { label in
                label.font = .systemFont(ofSize: 36.0, weight: .bold)
            })
            
            titleLabel.appearingTransition = VisibilityTransition.slideIn(after: 0.0, for: 0.5)
            
            column.add(child: titleLabel)
            
            var detailLabel = TransitionContainer(wrapping: Label(text: "Earn 1 point for every $1 spent.\nRedeem points for rewards.") { label in
                label.font = .systemFont(ofSize: 18.0, weight: .regular)
            })
            
            detailLabel.appearingTransition = VisibilityTransition.slideIn(after: 0.5, for: 0.4)
            
            column.add(child: detailLabel)
        })
    }
    
    var rightInput : Element {
        var content = TransitionContainer(wrapping: Column { column in
            column.verticalUnderflow = .justifyToStart
            column.horizontalAlignment = .fill
            column.minimumVerticalSpacing = 20.0
            
            column.add(child: Label(text: "Phone number") { label in
                label.font = .systemFont(ofSize: 18.0, weight: .semibold)
            })
            
            var textField = TextField(text: "")
            textField.placeholder = "enter phone number"
            
            column.add(child: textField)
            
            column.add(child: Row { row in
                row.horizontalUnderflow = .growProportionally
                row.verticalAlignment = .fill
                row.minimumHorizontalSpacing = 20.0
                
                row.add(child: Button(title: "No Thanks"))
                row.add(child: Button(title: "Check In"))
            })
            
            let disclaimer = "By claiming your points, you will get automated marketing texts associated with the loyalty program. Joining this program is not a condition of purchase."
            
            column.add(child: Label(text: disclaimer) { label in
                label.color = .lightGray
                label.font = .systemFont(ofSize: 14.0, weight: .regular)
            })
        })
        
        content.appearingTransition = VisibilityTransition.slideIn(after: 0.75, for: 0.5)
        
        return content
    }
    
    struct Button : ProxyElement
    {
        var title : String
        
        var elementRepresentation: Element {
            let content = Centered(ConstrainedSize(height: .atLeast(60.0), wrapping: Label(text: self.title) { label in
                label.font = .systemFont(ofSize: 16.0, weight: .semibold)
            }))
            
            return BlueprintUICommonControls.Button(wrapping: Box(backgroundColor: .init(white: 0.95, alpha: 1.0), wrapping: content))
        }
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
