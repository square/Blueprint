import XCTest
import BlueprintUI
@testable import BlueprintUICommonControls


class ButtonTests: XCTestCase {

    func test_snapshots() {

        do {
            let button = Button(wrapping: Label(text: "Hello, world"))
            compareSnapshot(of: button, identifier: "button_simple")
        }

        do {
            var button = Button(wrapping: Label(text: "Hello, world"))
            button.isEnabled = false
            compareSnapshot(of: button, identifier: "button_disabled")
        }

    }

}

