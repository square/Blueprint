import Foundation

/// A two-way binding between a focusable element's backing view and a `FocusState`-wrapped
/// property.
///
/// Generally you should not need to interact with this type directly. However, you can use focus
/// bindings to add focus support to custom elements.
///
/// ## Adding Focus Bindings
///
/// On a `FocusState`, call the `binding(for:)` method to get a binding bound to an optional value,
/// or `binding()` to get a binding bound to a boolean.
///
/// To set up the 2-way binding, there are 2 steps:
///
/// 1. Assign actions to the nested `FocusTrigger`, so that your backing view is updated when the
///    `FocusState`'s value changes.
///
/// 2. Call the `onFocus` and `onBlur` callbacks when your backing view gains or loses focus, so
///    that the value of the bound `FocusState` is updated.
///
/// ## Example
///
///     final class FocusableView: UIView {
///         var focusBinding: FocusBinding? {
///             didSet {
///                 oldValue?.trigger.focusAction = nil
///                 oldValue?.trigger.blurAction = nil
///
///                 guard let focusBinding = focusBinding else { return }
///
///                 focusBinding.trigger.focusAction = { [weak self] in
///                     self?.becomeFirstResponder()
///                 }
///                 focusBinding.trigger.blurAction = { [weak self] in
///                     self?.resignFirstResponder()
///                 }
///
///                 if isFirstResponder {
///                     focusBinding.onFocus()
///                 } else {
///                     focusBinding.onBlur()
///                 }
///             }
///         }
///
///         @discardableResult
///         override func becomeFirstResponder() -> Bool {
///             let focused = super.becomeFirstResponder()
///             if focused {
///                 focusBinding?.onFocus()
///             }
///             return focused
///         }
///
///         @discardableResult
///         override func resignFirstResponder() -> Bool {
///             let blurred = super.resignFirstResponder()
///             if blurred {
///                 focusBinding?.onBlur()
///             }
///             return blurred
///         }
///     }
///
/// - Tag: FocusBinding
///
public struct FocusBinding {
    /// A trigger, which is responsible for piping focus changes from a `FocusState` into a backing
    /// view.
    public let trigger = FocusTrigger()
    /// A callback to be called by a backing view when it is focused, to pipe changes from a backing
    /// view to a bound `FocusState`.
    public var onFocus: () -> Void
    /// A callback to be called by a backing view when it loses focus, to pipe changes from a
    /// backing view to a bound `FocusState`.
    public var onBlur: () -> Void

    /// Creates a new binding
    public init(onFocus: @escaping () -> Void, onBlur: @escaping () -> Void) {
        self.onFocus = onFocus
        self.onBlur = onBlur
    }
}
