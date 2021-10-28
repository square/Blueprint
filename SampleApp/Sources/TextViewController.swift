//
//  TextViewController.swift
//  SampleApp
//
//  Created by Kyle Bashour on 10/27/21.
//  Copyright © 2021 Square. All rights reserved.
//

import BlueprintUI
import BlueprintUICommonControls
import UIKit

class TextViewController: UIViewController {

    let blueprintView = BlueprintView()

    override func loadView() {
        view = blueprintView
    }

    override func viewDidLoad() {
        super.viewDidLoad()


        let text = NSAttributedString(
            string: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. (615) 290-0715",
            attributes: [
                .font: UIFont.systemFont(ofSize: 17),
            ]
        )


        blueprintView.element = Column { column in

            column.verticalUnderflow = .justifyToStart
            column.minimumVerticalSpacing = 20

            column.add(
                child: Fpp(attributedText: text) {
                    $0.textRectOffset = .init(horizontal: 0, vertical: 0)
                }
                .box(background: .red.withAlphaComponent(0.1))
                .constrainedTo(height: .absolute(30))
            )

            column.add(
                child: AttributedLabel(attributedText: text) {
                    $0.textRectOffset = .init(horizontal: 0, vertical: 0)
                }
                .box(background: .red.withAlphaComponent(0.1))
                .constrainedTo(height: .absolute(30))
            )
        }
        .inset(horizontal: 20, vertical: 100)

//        blueprintView.element = Overlay(elements: {
//            Fpp(attributedText: text) {
//                $0.textRectOffset = .init(horizontal: 0, vertical: 5)
//            }
//
//            AttributedLabel(attributedText: text) {
//                $0.textRectOffset = .init(horizontal: 0, vertical: 5)
//            }
//        })
//        .inset(horizontal: 20, vertical: 100)

    }
}
