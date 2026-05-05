import BlueprintUI
import XCTest
@testable import BlueprintUICommonControls


class TappableTests: XCTestCase {

    func test_tappable_exposesButtonTraitWithoutHidingLabel() {
        let element = Label(text: "Tap").tappable {}
        let view = BlueprintView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

        element.accessBackingView(in: view) { tappableView in
            let accessibilityView = tappableView.subviews[0]

            XCTAssertTrue(accessibilityView.isAccessibilityElement)
            XCTAssertTrue(accessibilityView.accessibilityTraits.contains(.button))
            XCTAssertEqual(accessibilityView.accessibilityLabel, "Tap")
        }
    }
}
