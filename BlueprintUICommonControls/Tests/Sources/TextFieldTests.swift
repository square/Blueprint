import BlueprintUI
import XCTest
@testable import BlueprintUICommonControls


class TextFieldTests: XCTestCase {

    func test_snapshots() {

        do {
            let field = TextField(text: "Hello, world")
            compareSnapshot(
                of: field,
                size: CGSize(width: 200, height: 44),
                identifier: "simple"
            )
        }

        do {
            var field = TextField(text: "")
            field.placeholder = "Type something..."
            compareSnapshot(
                of: field,
                size: CGSize(width: 200, height: 44),
                identifier: "placeholder"
            )
        }

        do {
            var field = TextField(text: "Disabled")
            field.isEnabled = false
            compareSnapshot(
                of: field,
                size: CGSize(width: 200, height: 44),
                identifier: "disabled"
            )
        }

        do {
            var field = TextField(text: "Right Aligned")
            field.textAlignment = .right
            compareSnapshot(
                of: field,
                size: CGSize(width: 200, height: 44),
                identifier: "right-aligned"
            )
        }

        do {
            var field = TextField(text: "Title font")
            field.font = .preferredFont(forTextStyle: .title1)
            compareSnapshot(
                of: field,
                size: CGSize(width: 200, height: 44),
                identifier: "title-font"
            )
        }

        do {
            var field = TextField(text: "Blue text color")
            field.textColor = .blue
            compareSnapshot(
                of: field,
                size: CGSize(width: 200, height: 44),
                identifier: "blue-text-color"
            )
        }

    }

    func test_focus() {
        // make a fake window so that focus works
        withWindow { window in
            let view = BlueprintView()
            window.addSubview(view)

            var isFocused = true
            let binding = FocusBinding(
                onFocus: { isFocused = true },
                onBlur: { isFocused = false }
            )
            view.element = TextField(text: "") { textField in
                textField.focusBinding = binding
            }

            view.layoutIfNeeded()
            let testView = view.subviews[0].subviews[0]

            XCTAssertFalse(testView.isFirstResponder)
            XCTAssertFalse(isFocused)

            binding.trigger.focus()
            XCTAssertTrue(testView.isFirstResponder)
            XCTAssertTrue(isFocused)

            binding.trigger.blur()
            XCTAssertFalse(testView.isFirstResponder)
            XCTAssertFalse(isFocused)
        }
    }
}
