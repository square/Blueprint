import XCTest
import BlueprintUI
@testable import BlueprintUICommonControls


class ButtonTests: XCTestCase {

    func test_snapshots() {

        let label = Label(text: "Hello, world") { (label) in
            label.roundingScale = 1
        }

        do {
            let button = Button(wrapping: label)
            compareSnapshot(of: button, identifier: "simple")
        }

        do {
            var button = Button(wrapping: label)
            button.isEnabled = false
            compareSnapshot(of: button, identifier: "disabled")
        }

    }

}

