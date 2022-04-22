//
//  DatePicker.swift
//  BlueprintUICommonControls
//
//  Created by Kyle Bashour on 4/22/22.
//

import BlueprintUI

public struct DatePicker: Element {

    public var date: Date?

    public var minimumDate: Date?

    public var maximumDate: Date?

    public var datePickerMode: UIDatePicker.Mode = .dateAndTime

    private var _preferredDatePickerStyle: Any?

    @available(iOS 13.4, *)
    public var preferredDatePickerStyle: UIDatePickerStyle {
        get { _preferredDatePickerStyle as? UIDatePickerStyle ?? .automatic }
        set { _preferredDatePickerStyle = newValue }
    }

    public var onChange: (Date) -> Void

    public init(
        date: Date?,
        onChange: @escaping (Date) -> Void,
        configure: ((inout DatePicker) -> Void)? = nil
    ) {
        self.date = date
        self.onChange = onChange
        configure?(&self)
    }

    public var content: ElementContent {
        struct Measurer {
            private static let prototypeDatePicker = NativeDatePicker()

            func measure(model: DatePicker, in constraint: SizeConstraint, environment: Environment) -> CGSize {
                let datePicker = Self.prototypeDatePicker
                datePicker.apply(model: model)
                var size = datePicker.sizeThatFits(constraint.minimum)

                if let constrainedWidth = constraint.width.constrainedValue {
                    size.width = constrainedWidth
                }

                return size
            }
        }

        return ElementContent { sizeConstraint, environment -> CGSize in
            Measurer().measure(model: self, in: sizeConstraint, environment: environment)
        }
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        NativeDatePicker.describe { config in
            config.builder = {
                NativeDatePicker(frame: context.bounds)
            }

            config.apply { view in
                view.apply(model: self)
            }
        }
    }
}

extension DatePicker {

    private final class NativeDatePicker: UIDatePicker {
        private var onChange: ((Date) -> Void)?

        override init(frame: CGRect) {
            super.init(frame: frame)
            addTarget(self, action: #selector(dateDidChange), for: .valueChanged)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc private func dateDidChange() {
            onChange?(date)
        }

        func apply(model: DatePicker) {
            minimumDate = model.minimumDate
            maximumDate = model.maximumDate
            datePickerMode = model.datePickerMode
            onChange = model.onChange

            if #available(iOS 13.4, *) {
                // There is a UIKit bug where setting certain date picker styles resets the frame width to 320pts,
                // so we need to store the before-frame and set it again after setting the style.
                let frame = self.frame
                preferredDatePickerStyle = model.preferredDatePickerStyle
                self.frame = frame
            }

            if let date = model.date {
                self.date = date
            }
        }
    }
}
