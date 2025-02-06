import BlueprintUI
import UIKit
import XCTest


class UIAccessibilityTraits_Tests: XCTestCase {

    func test_backButton() throws {
        let root = UIViewController()
        let second = UIViewController()
        let navigationController = UINavigationController()
        navigationController.viewControllers = [root, second]

        show(vc: navigationController) { _ in

            let button = navigationController.navigationBar.findSubview(ofType: UIControl.self)

            /// The `.backButton` trait is private, so this test is here to verify it does not change.

            XCTAssertEqual(button!.accessibilityTraits, .backButton)
        }
    }

    func test_toggleSwitch() throws {

        if #available(iOS 17.0, *) {
            /// The `.toggleButton` trait is exposed iOS 17, so this test is here to verify it matches ours.
            XCTAssertEqual(UIAccessibilityTraits._toggleButton, UIAccessibilityTraits.toggleButton)
        }

        let uiSwitch = UISwitch()
        /// The `.toggleButton` trait is private prior to iOS 17, so this test is here to verify it exists on prior versions.
        XCTAssertTrue(uiSwitch.accessibilityTraits.contains(._toggleButton))
    }
}
