import BlueprintUI
import UIKit

/// A trigger that moves VoiceOver focus to a backing view.
///
/// Like `FocusTrigger`, this uses late-binding: create the trigger
/// before any view exists, bind it to a backing view during layout,
/// and invoke it later to move VoiceOver focus.
///
/// ## Example
///
///     let errorFocusTrigger = AccessibilityFocusTrigger()
///
///     // In the element tree:
///     Label(text: "Invalid amount")
///         .accessibilityFocus(trigger: errorFocusTrigger)
///
///     // After validation fails:
///     errorFocusTrigger.requestFocus()
///
public final class AccessibilityFocusTrigger {

    /// The type of accessibility notification to post when requesting focus.
    public enum Notification {
        /// Use for focus changes within the current screen.
        case layoutChanged
        /// Use for major screen transitions.
        case screenChanged

        var uiAccessibilityNotification: UIAccessibility.Notification {
            switch self {
            case .layoutChanged:
                return .layoutChanged
            case .screenChanged:
                return .screenChanged
            }
        }
    }

    /// The notification type to post when focus is requested.
    public let notification: Notification

    /// Creates a new trigger, not yet bound to any view.
    /// - Parameter notification: The type of accessibility notification to post. Defaults to `.layoutChanged`.
    public init(notification: Notification = .layoutChanged) {
        self.notification = notification
    }

    /// Bound by the backing view during apply().
    /// The closure posts `UIAccessibility.post(notification:argument:)`
    /// targeting the bound view.
    var action: (() -> Void)?

    /// Moves VoiceOver focus to the bound backing view.
    /// No-op if VoiceOver is not running or trigger is unbound.
    public func requestFocus() {
        action?()
    }

}

extension Element {

    /// Binds an `AccessibilityFocusTrigger` to this element.
    ///
    /// When `trigger.requestFocus()` is called, VoiceOver focus
    /// moves to this element's backing view.
    ///
    /// - Parameter trigger: A trigger that can later be used to move VoiceOver focus to this element.
    /// - Returns: A wrapping element that provides a backing view for VoiceOver focus.
    public func accessibilityFocus(
        trigger: AccessibilityFocusTrigger
    ) -> Element {
        AccessibilityFocusableElement(
            wrapped: self,
            trigger: trigger
        )
    }
}
