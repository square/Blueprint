import BlueprintUI
import XCTest

final class FocusStateTests: XCTestCase {
    func test_enum() {
        enum Field {
            case a, b
        }

        struct StateHolder {
            @FocusState var focusedField: Field?
        }
        let state = StateHolder()

        var isFocusedA: Bool = false
        var isFocusedB: Bool = false

        let bindingA = state.$focusedField.binding(for: .a)
        bindingA.trigger.focusAction = { isFocusedA = true }
        bindingA.trigger.blurAction = { isFocusedA = false }

        let bindingB = state.$focusedField.binding(for: .b)
        bindingB.trigger.focusAction = { isFocusedB = true }
        bindingB.trigger.blurAction = { isFocusedB = false }

        state.focusedField = .a
        XCTAssertEqual(isFocusedA, true)
        XCTAssertEqual(isFocusedB, false)

        state.focusedField = .b
        XCTAssertEqual(isFocusedA, false)
        XCTAssertEqual(isFocusedB, true)

        state.focusedField = nil
        XCTAssertEqual(isFocusedA, false)
        XCTAssertEqual(isFocusedB, false)

        bindingA.onFocus()
        XCTAssertEqual(state.focusedField, .a)

        bindingA.onBlur()
        XCTAssertEqual(state.focusedField, nil)

        bindingB.onFocus()
        XCTAssertEqual(state.focusedField, .b)

        bindingB.onBlur()
        XCTAssertEqual(state.focusedField, nil)
    }

    func test_bool() {
        struct StateHolder {
            @FocusState var isFocused: Bool
        }
        let state = StateHolder()

        var isFocused: Bool = false

        let binding = state.$isFocused.binding()
        binding.trigger.focusAction = { isFocused = true }
        binding.trigger.blurAction = { isFocused = false }

        state.isFocused = true
        XCTAssertEqual(isFocused, true)

        state.isFocused = false
        XCTAssertEqual(isFocused, false)

        binding.onFocus()
        XCTAssertEqual(state.isFocused, true)

        binding.onBlur()
        XCTAssertEqual(state.isFocused, false)
    }
}
