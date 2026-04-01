import UIKit

/// A wrapping element that binds an `AccessibilityFocusTrigger` to a backing view,
/// enabling VoiceOver focus to be programmatically moved to the wrapped element.
struct AccessibilityFocusableElement: Element {

    var wrapped: Element
    var trigger: AccessibilityFocusTrigger

    // MARK: Element

    var content: ElementContent {
        ElementContent(child: wrapped)
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        BackingView.describe { config in
            config.apply { view in
                view.apply(trigger: self.trigger)
            }
        }
    }
}

// MARK: - Backing View

extension AccessibilityFocusableElement {

    private final class BackingView: UIView {

        private var currentTrigger: AccessibilityFocusTrigger?

        func apply(trigger: AccessibilityFocusTrigger) {
            // Tear down old trigger binding.
            currentTrigger?.action = nil

            currentTrigger = trigger

            // Bind the new trigger to this view.
            let notification = trigger.notification
            trigger.action = { [weak self] in
                guard let self, UIAccessibility.isVoiceOverRunning else { return }
                UIAccessibility.post(
                    notification: notification.uiAccessibilityNotification,
                    argument: self
                )
            }
        }

        override var isAccessibilityElement: Bool {
            get { false }
            set {}
        }
    }
}
