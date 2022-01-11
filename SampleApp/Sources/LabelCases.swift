//
//  LabelCases.swift
//  SampleApp
//
//  Created by Kyle Bashour on 1/11/22.
//  Copyright © 2022 Square. All rights reserved.
//

import BlueprintUI
import BlueprintUICommonControls
import Foundation
import UIKit

class LabelCasesViewController: UIViewController {

    let blueprintView = BlueprintView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(blueprintView)

        let text = """
        Hello, this is a long string that should wrap to at least three lines. I hope it does at least. But actually we need a lot more text. Something like this.
        """

        blueprintView.element = Column(alignment: .fill, minimumSpacing: 8) {
            for lineBreakMode in [
                NSLineBreakMode.byClipping,
                .byWordWrapping,
                .byCharWrapping,
                .byTruncatingHead,
                .byTruncatingMiddle,
                .byTruncatingTail,
            ] {
                Label(text: "\(lineBreakMode)") { label in
                    label.font = .boldSystemFont(ofSize: UIFont.systemFontSize)
                }
                for numberOfLines in [0, 1, 2] {
                    Label(text: text) { label in
                        label.font = .systemFont(ofSize: UIFont.labelFontSize)
                        label.numberOfLines = numberOfLines
                        label.lineBreakMode = lineBreakMode
                    }
                }
            }
        }
        .inset(uniform: 8)
        .scrollable()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        blueprintView.frame = view.bounds
    }
}

extension NSLineBreakMode {
    static var all: [NSLineBreakMode] {
        [
            .byClipping,
            .byWordWrapping,
            .byCharWrapping,
            .byTruncatingHead,
            .byTruncatingMiddle,
            .byTruncatingTail,
        ]
    }
}

extension NSLineBreakMode: CustomStringConvertible {
    public var description: String {
        switch self {
        case .byClipping: return "byClipping"
        case .byWordWrapping: return "byWordWrapping"
        case .byCharWrapping: return "byCharWrapping"
        case .byTruncatingHead: return "byTruncatingHead"
        case .byTruncatingMiddle: return "byTruncatingMiddle"
        case .byTruncatingTail: return "byTruncatingTail"
        }
    }
}
