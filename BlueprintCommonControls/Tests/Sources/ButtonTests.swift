import XCTest
import Blueprint
@testable import BlueprintCommonControls


class ButtonTests: XCTestCase {

    func test_snapshots() {

        do {
            let button = Button(wrapping: Label(text: "Hello, world"))
            compareSnapshot(of: button, identifier: "simple")
        }

        do {
            var button = Button(wrapping: Label(text: "Hello, world"))
            button.isEnabled = false
            compareSnapshot(of: button, identifier: "disabled")
        }

    }

}

