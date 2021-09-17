import Foundation

/// A trigger for focus and blur actions.
///
/// This type is meant to be used in conjunction with `FocusState`; you will usually not create
/// it directly. For information about adding focus support to a custom element, see `FocusBinding`.
///
/// Triggers allow imperative actions to be invoked on backing views, by creating a trigger in a
/// declarative model before the view is realized, late-binding the actions to a backing view after
/// that view has been realized, and then invoking the action on the trigger later in response to
/// some other event.
///
/// ## See Also
/// [FocusBinding](x-source-tag://FocusBinding)
///
public final class FocusTrigger {
    /// Create a new trigger, not yet bound to any view.
    public init() {}

    /// The action to be invoked on focus, which will be set by a backing view.
    public var focusAction: (() -> Void)?
    /// The action to be invoked on blur, which will be set by a backing view.
    public var blurAction: (() -> Void)?

    /// Focuses the backing view bound to this trigger.
    public func focus() {
        focusAction?()
    }

    /// Blurs (removes focus from) the backing view bound to this trigger.
    public func blur() {
        blurAction?()
    }
}
