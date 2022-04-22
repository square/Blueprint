//
//  DateViewController.swift
//  SampleApp
//
//  Created by Kyle Bashour on 4/22/22.
//  Copyright © 2022 Square. All rights reserved.
//

import BlueprintUI
import BlueprintUICommonControls
import UIKit

final class DateViewController: UIViewController {

    private struct State {
        var date: Date?
    }

    private let blueprintView = BlueprintView()

    private var state = State() {
        didSet {
            update()
        }
    }

    override func loadView() {
        view = blueprintView
        blueprintView.element = element
    }

    private func update() {
        blueprintView.element = element
    }

    var element: Element {
        Column(alignment: .fill, minimumSpacing: 8) {
            DatePicker(date: state.date) { [weak self] date in
                self?.state.date = date
            }

            if #available(iOS 13.4, *) {
                DatePicker(date: state.date) { [weak self] date in
                    self?.state.date = date
                } configure: { picker in
                    picker.preferredDatePickerStyle = .wheels
                }
            }

            if #available(iOS 14, *) {
                DatePicker(date: state.date) { [weak self] date in
                    self?.state.date = date
                } configure: { picker in
                    picker.preferredDatePickerStyle = .inline
                }
            }
        }
        .inset(uniform: 8)
        .scrollable()
    }
}
