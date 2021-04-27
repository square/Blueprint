//
//  BlueprintScrollViewController.swift
//  SampleApp
//
//  Created by Kyle Bashour on 4/26/21.
//  Copyright © 2021 Square. All rights reserved.
//

import UIKit
import BlueprintUI
import BlueprintUICommonControls

class BlueprintScrollViewController: UIViewController {

    let bp = BlueprintView()

    private var labelCoordinate: UICoordinateSpace?

    override func loadView() {
        view = bp
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        render()
    }

    func render() {
        bp.element = Overlay(elements: [
            Label(text: "Hello world!")
                .emitCoordinateSpace {
                    self.labelCoordinate = $0
                    self.render()
                }
                .aligned(vertically: .center, horizontally: .leading)
                .inset(uniform: 20)
                .scrollable {
                    $0.alwaysBounceVertical = true
                },

            LayoutWriter { context, builder in
                if let anchor = self.labelCoordinate {
                    let labelFrame = anchor.convert(anchor.bounds, to: self.bp)
                    let badgeFrame = CGRect(x: labelFrame.maxX + 10, y: labelFrame.minY - 10, width: 10, height: 10)

                    builder.add(.init(frame: badgeFrame, element: Box(backgroundColor: .purple)))
                }
            }
        ])
    }
}

