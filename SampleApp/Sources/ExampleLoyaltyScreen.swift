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
        
        blueprintView.setElement(animated: animated, Screen())
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
            row.minimumHorizontalSpacing = 40.0
            
            row.add(growPriority: 0.0, child: self.leftInfo)
            
            row.add(growPriority: 1.0, child: self.rightInput)
        }
    }
    
    var leftInfo : Element {
        return Column { column in
            column.verticalUnderflow = .growProportionally
            column.horizontalAlignment = .fill
            column.minimumVerticalSpacing = 20.0
            
            column.add(child: AppearanceTransition(
                onAppear: .slideIn(),
                wrapping: Label(text: "Get 10 points for your purchase today.") { label in
                    label.font = .systemFont(ofSize: 36.0, weight: .bold)
            }))
            
            column.add(child: AppearanceTransition(
                onAppear: .slideIn(after: 0.5),
                wrapping: Label(text: "Earn 1 point for every $1 spent.\nRedeem points for rewards.") { label in
                label.font = .systemFont(ofSize: 18.0, weight: .regular)
            }))
        }
    }
    
    var rightInput : Element {
        return AppearanceTransition(
            onAppear: .slideIn(after: 1.0),
            
            wrapping: ConstrainedSize(
                width: .absolute(300),
                
                wrapping: Column { column in
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
                }
            )
        )
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

