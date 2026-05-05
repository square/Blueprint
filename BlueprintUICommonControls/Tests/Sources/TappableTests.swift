import BlueprintUI
import XCTest
@testable import BlueprintUICommonControls


class TappableTests: XCTestCase {

    func test_accessibilityTraits() {
        let element = Label(text: "Tap").tappable {}
        let view = BlueprintView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        element.accessBackingView(in: view) { view in
            XCTAssertTrue(view.isAccessibilityElement)
            XCTAssertTrue(view.accessibilityTraits.contains(.button))
        }
    }

    func test_accessibilityCombine_inheritsButtonTrait() {
        let element = Label(text: "Tap")
            .tappable {}
            .accessibilityCombine(blockWhenNotAccessible: false)

        let view = BlueprintView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        element.accessBackingView(in: view) { view in
            view.setNeedsLayout()
            view.layoutIfNeeded()

            XCTAssertTrue(view.isAccessibilityElement)
            XCTAssertTrue(view.accessibilityTraits.contains(.button))
        }
    }
}
