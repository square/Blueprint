//
//  ControlViewController.swift
//  SampleApp
//
//  Created by Kyle Van Essen on 12/15/20.
//  Copyright © 2020 Square. All rights reserved.
//

import UIKit
import BlueprintUI
import BlueprintUICommonControls


final class ControlViewController : UIViewController {
    
    let blueprintView = BlueprintView()

    override func loadView() {
        self.view = self.blueprintView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        update()
    }

    func update() {
        self.blueprintView.element = self.element
    }

    var element: Element {
        
        Button {
            print("Tapped!!")
        } content: { state in
            Button.Content {
                Column { column in
                    column.horizontalAlignment = .fill
                    column.minimumVerticalSpacing = 5.0
                    
                    column.addFixed(child: Label(text: "Charge $30.60") { label in
                        label.font = .systemFont(ofSize: 24.0, weight: .semibold)
                        label.color = .white
                        label.alignment = .center
                    })
                    
                    column.addFixed(child: Label(text: "Including Tax") { label in
                        label.font = .systemFont(ofSize: 14.0, weight: .regular)
                        label.color = .white
                        label.alignment = .center
                    })
                }
                .inset(uniform: 20.0)
                .box(
                    background: {
                        if state == .highlighted {
                            return UIColor.systemBlue.withAlphaComponent(0.95)
                        } else {
                            return .systemBlue
                        }
                    }(),
                     corners: .rounded(radius: 10.0)
                )
            } accessibility: {
                .init(
                    label: "Charge $30.60",
                    hint: "Including Tax",
                    value: "$30.60"
                )
            }
        }
        .centered()
    }
}
