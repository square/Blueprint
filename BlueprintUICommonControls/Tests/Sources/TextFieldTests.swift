import XCTest
import BlueprintUI
@testable import BlueprintUICommonControls


class TextFieldTests: XCTestCase {

    func test_snapshots() {

        do {
            let field = TextField(text: "Hello, world")
            compareSnapshot(
                of: field,
                size: CGSize(width: 200, height: 44),
                identifier: "simple")
        }

        do {
            var field = TextField(text: "")
            field.placeholder = "Type something..."
            compareSnapshot(
                of: field,
                size: CGSize(width: 200, height: 44),
                identifier: "placeholder")
        }

        do {
            var field = TextField(text: "Disabled")
            field.isEnabled = false
            compareSnapshot(
                of: field,
                size: CGSize(width: 200, height: 44),
                identifier: "disabled")
        }
        
        do {
            var field = TextField(text: "Right Aligned")
            field.textAlignment = .right
            compareSnapshot(
                of: field,
                size: CGSize(width: 200, height: 44),
                identifier: "right-aligned")
        }

        do {
            var field = TextField(text: "Title font")
            field.font = .preferredFont(forTextStyle: .title1)
            compareSnapshot(
                of: field,
                size: CGSize(width: 200, height: 44),
                identifier: "title-font")
        }

    }

}

