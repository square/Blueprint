import BlueprintUI

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
