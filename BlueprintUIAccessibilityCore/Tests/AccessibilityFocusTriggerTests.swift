import BlueprintUI
@testable import BlueprintUIAccessibilityCore
import XCTest

final class AccessibilityFocusTriggerTests: XCTestCase {

    // MARK: - Trigger

    func test_unbound_requestFocus_is_noop() {
        let trigger = AccessibilityFocusTrigger()
        // Should not crash or have any effect.
        trigger.requestFocus()
    }

    func test_bound_requestFocus_invokes_action() {
        let trigger = AccessibilityFocusTrigger()

        var didInvoke = false
        trigger.action = {
            didInvoke = true
        }

        trigger.requestFocus()
        XCTAssertTrue(didInvoke)
    }

    func test_action_is_cleared_on_rebind() {
        let trigger = AccessibilityFocusTrigger()

        var invokeCount = 0
        trigger.action = {
            invokeCount += 1
        }

        trigger.requestFocus()
        XCTAssertEqual(invokeCount, 1)

        // Simulate rebinding (as would happen when a new backing view takes over).
        trigger.action = nil

        trigger.requestFocus()
        XCTAssertEqual(invokeCount, 1, "Action should not fire after being cleared")
    }

    func test_default_notification_is_layoutChanged() {
        let trigger = AccessibilityFocusTrigger()
        switch trigger.notification {
        case .layoutChanged:
            break // Expected
        case .screenChanged:
            XCTFail("Expected default notification to be .layoutChanged")
        }
    }

    func test_screenChanged_notification() {
        let trigger = AccessibilityFocusTrigger(notification: .screenChanged)
        switch trigger.notification {
        case .screenChanged:
            break // Expected
        case .layoutChanged:
            XCTFail("Expected notification to be .screenChanged")
        }
    }

    // MARK: - Element modifier

    func test_accessibilityFocus_modifier_wraps_element() {
        let trigger = AccessibilityFocusTrigger()
        let base = TestElement()
        let wrapped = base.accessibilityFocus(trigger: trigger)
        XCTAssertTrue(wrapped is AccessibilityFocusableElement)
    }
}

// MARK: - Helpers

private struct TestElement: Element {
    var content: ElementContent {
        ElementContent(intrinsicSize: CGSize(width: 100, height: 44))
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
}
