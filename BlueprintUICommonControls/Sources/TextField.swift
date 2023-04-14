import BlueprintUI
import UIKit


/// Displays a text field.
public struct TextField: Element {

    public var text: String
    public var placeholder: String = ""
    public var onChange: ((String) -> Void)? = nil
    public var secure: Bool = false
    public var isEnabled: Bool = true
    public var textAlignment: NSTextAlignment = .left
    public var font: UIFont = .preferredFont(forTextStyle: .body)
    public var textColor: UIColor = .black

    public var clearButtonMode: UITextField.ViewMode = .never

    public var keyboardType: UIKeyboardType = .default
    public var keyboardAppearance: UIKeyboardAppearance = .default

    public var autocapitalizationType: UITextAutocapitalizationType = .sentences
    public var autocorrectionType: UITextAutocorrectionType = .default
    public var spellCheckingType: UITextSpellCheckingType = .default
    public var textContentType: UITextContentType? = nil

    public var onReturn: (() -> Void)?
    public var returnKeyType: UIReturnKeyType = .default
    public var enablesReturnKeyAutomatically: Bool = false

    public var focusBinding: FocusBinding?

    /// A set of accessibility traits that should be applied to the field, these will be merged with any existing traits.
    /// These traits should relate to the content of the text, for example `.header`, `.link`, or `.updatesFrequently`.
    public var accessibilityTraits: Set<AccessibilityElement.Trait>?

    public init(text: String, configure: (inout TextField) -> Void = { _ in }) {
        self.text = text
        configure(&self)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        CallbackTextField.describe { configuration in
            configuration[\.backgroundColor] = .clear

            configuration[\.text] = text
            configuration[\.placeholder] = placeholder
            configuration[\.onChange] = onChange
            configuration[\.isSecureTextEntry] = secure
            configuration[\.isEnabled] = isEnabled
            configuration[\.textAlignment] = textAlignment
            configuration[\.font] = font
            configuration[\.textColor] = textColor

            configuration[\.clearButtonMode] = clearButtonMode

            configuration[\.keyboardType] = keyboardType
            configuration[\.keyboardAppearance] = keyboardAppearance

            configuration[\.autocapitalizationType] = autocapitalizationType
            configuration[\.autocorrectionType] = autocorrectionType
            configuration[\.spellCheckingType] = spellCheckingType
            configuration[\.textContentType] = textContentType

            configuration[\.onReturn] = onReturn
            configuration[\.returnKeyType] = returnKeyType
            configuration[\.enablesReturnKeyAutomatically] = enablesReturnKeyAutomatically

            configuration[\.focusBinding] = focusBinding

            if let traits = accessibilityTraits {
                if let existing = configuration[\.accessibilityTraits] {
                    configuration[\.accessibilityTraits] = existing.union(UIAccessibilityTraits(with: traits))
                } else {
                    configuration[\.accessibilityTraits] = UIAccessibilityTraits(with: traits)
                }
            }
        }
    }

    public var content: ElementContent {
        ElementContent { constraint, environment -> CGSize in
            switch environment.layoutMode {
            case .legacy:
                return CGSize(
                    width: max(constraint.maximum.width, 44),
                    height: 44.0
                )
            case .caffeinated:
                return CGSize(
                    width: constraint.width.constrainedValue.map { max($0, 44) } ?? .infinity,
                    height: 44
                )
            }
        }
    }

}


fileprivate final class CallbackTextField: UITextField, UITextFieldDelegate {

    var onChange: ((String) -> Void)? = nil
    var onReturn: (() -> Void)? = nil

    var focusBinding: FocusBinding? {
        didSet {
            oldValue?.trigger.focusAction = nil
            oldValue?.trigger.blurAction = nil

            guard let focusBinding = focusBinding else { return }

            focusBinding.trigger.focusAction = { [weak self] in
                self?.becomeFirstResponder()
            }
            focusBinding.trigger.blurAction = { [weak self] in
                self?.resignFirstResponder()
            }

            if isFirstResponder {
                focusBinding.onFocus()
            } else {
                focusBinding.onBlur()
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        delegate = self
        addTarget(self, action: #selector(textDidChange), for: .editingChanged)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func textDidChange() {
        onChange?(text ?? "")
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onReturn?()
        return true
    }

    @discardableResult
    override func becomeFirstResponder() -> Bool {
        let focused = super.becomeFirstResponder()
        if focused {
            focusBinding?.onFocus()
        }
        return focused
    }

    @discardableResult
    override func resignFirstResponder() -> Bool {
        let blurred = super.resignFirstResponder()
        if blurred {
            focusBinding?.onBlur()
        }
        return blurred
    }

}

extension TextField {
    /// Modifies this text field by binding its focus state to the given state value.
    ///
    /// Use this modifier to cause the text field to receive focus whenever the `state` equals
    /// the `value`. Typically, you create an enumeration of fields that may receive focus, bind an
    /// instance of this enumeration, and assign its cases to focusable views.
    ///
    /// The following example uses the cases of a `LoginForm` enumeration to bind the focus state of
    /// two `TextField` elements. A sign-in button validates the fields and sets the bound
    /// `focusedField` value to any field that requires the user to correct a problem.
    ///
    ///     struct LoginForm: ProxyElement {
    ///         enum Field: Hashable {
    ///             case username
    ///             case password
    ///         }
    ///
    ///         var username: String
    ///         var password: String
    ///         var handleLogin: () -> Void
    ///
    ///         @FocusState private var focusedField: Field?
    ///
    ///         var elementRepresentation: Element {
    ///             Column { column in
    ///                 column.add(
    ///                     child: TextField(text: "")
    ///                         .focused(when: $focusedField, equals: .username)
    ///                 )
    ///
    ///                 column.add(
    ///                     child: TextField(text: "")
    ///                         .focused(when: $focusedField, equals: .password)
    ///                 )
    ///
    ///                 column.add(
    ///                     child: Button(
    ///                         onTap: {
    ///                             if username.isEmpty {
    ///                                 focusedField = .username
    ///                             } else if password.isEmpty {
    ///                                 focusedField = .password
    ///                             } else {
    ///                                 handleLogin()
    ///                             }
    ///                         },
    ///                         wrapping: Label(text: "Sign In")
    ///                     )
    ///                 )
    ///             }
    ///         }
    ///     }
    ///
    /// To control focus using a Boolean, use the `focused(when:)` method instead.
    ///
    /// - Parameters:
    ///   - state: The state to bind to.
    ///
    ///     When focus moves to this text field, the binding sets the bound value to the
    ///     corresponding match value. If a caller sets the state value programmatically to the
    ///     matching value, then focus moves to this text field.
    ///
    ///     When focus leaves this text field, the binding sets the bound value to `nil`. Likewise,
    ///     if a caller sets the value to `nil`, this text field will lose focus.
    ///
    ///   - value: The value to match against when determining whether the binding should change.
    ///
    /// - Returns: A modified text field.
    public func focused<Value>(
        when state: FocusState<Value?>,
        equals value: Value
    ) -> Self {
        var textField = self
        textField.focusBinding = state.binding(for: value)
        return textField
    }

    /// Modifies this text field by binding its focus state to the given Boolean state value.
    ///
    /// Use this modifier to cause the text field to receive focus whenever the the `condition` is
    /// `true`. You can use this modifier to observe the focus state of a text field, or
    /// programmatically focus or blur the field.
    ///
    /// In the following example, a single text field accepts a user's desired `username`. The text
    /// field binds its focus state to the Boolean value `isUsernameFocused`. A "Submit" button's
    /// action checks if the username is empty, and sets `isUsernameFocused` to `true`, which causes
    /// focus to return to the text field.
    ///
    ///     struct SignupForm: ProxyElement {
    ///         var username: String
    ///         var onSignUpTapped: () -> Void
    ///
    ///         @FocusState var isUsernameFocused: Bool
    ///
    ///         var elementRepresentation: Element {
    ///             Column { column in
    ///                 column.add(
    ///                     child: TextField(text: username)
    ///                         .focused(when: $isUsernameFocused)
    ///                 )
    ///
    ///                 column.add(
    ///                     child: Button(
    ///                         onTap: {
    ///                             if username.isEmpty {
    ///                                 isUsernameFocused = true
    ///                             } else {
    ///                                 onSignUpTapped()
    ///                             }
    ///                         },
    ///                         wrapping: Label(text: "Submit")
    ///                     )
    ///                 )
    ///             }
    ///         }
    ///     }
    ///
    /// To control focus by matching a value, use the `focused(when:equals:)` method instead.
    ///
    /// - Parameters:
    ///   - condition: The state to bind to.
    ///
    ///     When focus moves to this text field, the binding sets the bound value to `true`. If a
    ///     caller sets the value to `true` programmatically, then focus moves to this text field.
    ///
    ///     When focus leaves this text field, the binding sets the bound value to `false`.
    ///     Likewise, if a caller sets the value to `false`, this text field will lose focus.
    ///
    /// - Returns: A modified text field.
    public func focused(when condition: FocusState<Bool>) -> Self {
        var textField = self
        textField.focusBinding = condition.binding()
        return textField
    }
}
