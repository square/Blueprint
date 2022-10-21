//
//  TwitterViewController.swift
//  SampleApp
//
//  Created by Kareem Daker on 10/21/22.
//  Copyright © 2022 Square. All rights reserved.
//

import BlueprintUI
import BlueprintUICommonControls
import UIKit


final class TwitterViewController: UIViewController {

    let gridSize = 30
    private let blueprintView = BlueprintView()

    private lazy var model: [[Int]] = {
        var cols = [[Int]]()
        for i in 0..<gridSize {
            var row = [Int]()
            for j in 0..<gridSize {
                row.append(0)
            }
            cols.append(row)
        }
        return cols
    }()

    override func loadView() {
        view = blueprintView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        update()
    }

    private func update() {
        blueprintView.element = element
    }

    var element: Element {

        Column { col in
            for (i, values) in model.enumerated() {
                col.horizontalAlignment = .fill
                let row = Row { row in
                    for (j, value) in values.enumerated() {
                        let label = Label(text: String(value))
                            .centered()
                            .constrainedTo(size: .init(width: 20, height: 20))
                            .box(background: .red)
                            .tappable {
                                self.model[i][j] = self.model[i][j] + 1
                                self.update()
                            }
                        row.add(child: label)
                    }
                }
                col.add(child: row)
            }
        }.inset(uniform: 20)
    }
}

struct Cell: ProxyElement {

    var elementRepresentation: Element {
        Row { row in
            let img = Box(
                backgroundColor: .black,
                cornerStyle: .capsule,
                cornerCurve: .circular,
                borderStyle: .solid(color: .red, width: 1.0),
                shadowStyle:,
                clipsContent: <#T##Bool#>,
                wrapping: <#T##Element?#>
            )
            row.add(child: img)
            Column { col in
                col.add(child: NameRow())
            }
        }
    }
}

struct NameRow: ProxyElement {
    var elementRepresentation: Element {
        Row { row in
            let name = Label(text: "test")
            row.add(child: name)

            let userName = Label(text: "test2")
            row.add(child: userName)

            let date = Label(text: "no").aligned(vertically: .center, horizontally: .trailing)
            row.add(child: date)
        }
    }
}
