import Foundation

/// A property wrapper type that can read and write a value that represents the placement of focus.
///
/// Use this property wrapper in conjunction with modifiers on elements that support focus, such as
/// `TextField.focused(when:equals:)` and `TextField.focused(when:)`, to describe when those elements
/// should have focus. When focus enters the modified element, the wrapped value of this property
/// updates to match a given value. Similarly, when focus leaves, the wrapped value of this property
/// resets to `nil` or `false`. Setting this property's value programmatically has the reverse
/// effect, causing focus to move to the element associated with the updated value.
///
/// In the following example of a simple login screen, when the user presses the Sign In button and
/// one of the fields is still empty, focus moves to that field. Otherwise, the sign-in process
/// proceeds.
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
/// To allow for cases where focus is completely absent from a view tree, the wrapped value must be
/// either an optional or a Boolean. Set the focus binding to `false` or `nil` as appropriate to
/// remove focus from all bound fields. You can also use this to remove focus from a ``TextField``
/// and thereby dismiss the keyboard.
///
/// ### Auto-Focus
///
/// To auto-focus a field when it appears, set the value in an `onAppear` hook.
///
///     struct Example: ProxyElement {
///         @FocusState var isFocused: Bool
///
///         var elementRepresentation: Element {
///             TextField(text: "")
///                 .focused(when: $isFocused)
///                 .onAppear {
///                     isFocused = true
///                 }
///         }
///     }
///
/// ### Avoid Ambiguous Focus Bindings
///
/// A `TextField` can have only one focus binding, stored in its `focusBinding` property. If you apply
/// the `focused` modifier multiple times, the last one will overwrite the previous value.
///
/// On the other hand, binding the same value to two views is ambiguous. In the following example,
/// two separate fields bind focus to the `name` value:
///
///     struct Content: ProxyElement {
///         enum Field: Hashable {
///             case name
///             case fullName
///         }
///
///         @FocusState private var focusedField: Field?
///
///         var elementRepresentation: Element {
///             Column { column in
///                 column.add(
///                     child: TextField(text: "")
///                         .focused(when: $focusedField, equals: .name)
///                 )
///
///                 column.add(
///                     child: TextField(text: "")
///                         .focused(when: $focusedField, equals: .name) // incorrect re-use of .name
///                 )
///             }
///         }
///     }
///
/// If the user moves focus to either field, the `focusedField` binding updates to `name`. However,
/// if the app programmatically sets the value to `name`, the last field bound will be chosen.
///
@propertyWrapper
public struct FocusState<Value> where Value: Hashable {

    @Storage private var value: Value

    /// Creates a focus state that binds to a Boolean.
    public init() where Value == Bool {
        value = false
    }

    /// Creates a focus state that binds to an optional type.
    public init<T>() where Value == T?, T: Hashable {
        value = nil
    }

    /// The current state value, taking into account whatever bindings might be
    /// in effect due to the current location of focus.
    ///
    /// When focus is not in any view that is bound to this state, the wrapped
    /// value will be `nil` (for optional-typed state) or `false` (for `Bool`-
    /// typed state).
    public var wrappedValue: Value {
        get { value }
        nonmutating set { value = newValue }
    }

    /// A projection of the focus state that can be bound to focusable elements.
    ///
    /// Use this property wrapper in conjunction with modifiers on elements that support focus, such
    /// as `TextField.focused(when:equals)` and `TextField.focused(when:)`, to describe when those
    /// elements should have focus.
    ///
    /// To add focus support to a custom element, use one of the methods on this projection to
    /// retrieve a `FocusBinding`: `binding()` for `Bool` values and `binding(for:)` for optional
    /// values.
    ///
    public var projectedValue: Self {
        self
    }

    private var storage: Storage { $value }

    private subscript(value: Value) -> FocusBinding {
        storage.binding(for: value)
    }

    /// Gets a focus binding associated with the `FocusState` being a specific value.
    ///
    /// You can use this binding to add focus support to a custom element.
    ///
    /// When the `FocusState` property is set to this value, the binding's `focus` trigger will
    /// fire, and when the property is set to another value, the binding's `blur` trigger will fire.
    /// Similarly, calling the `onFocus` callback will set the `FocusState` to this value, and the
    /// `onBlur` callback will set it to `nil`.
    ///
    /// ## See Also
    /// [FocusBinding](x-source-tag://FocusBinding)
    ///
    public func binding<T>(for value: T) -> FocusBinding where Value == T?, T: Hashable {
        self[value]
    }

    /// Gets a focus binding associated with the `FocusState` value being `true`.
    ///
    /// You can use this binding to add focus support to a custom element.
    ///
    /// When the `FocusState` property is set to true, the binding's `focus` trigger will fire, and
    /// when the property is set to false, the binding's `blur` trigger will fire. Similarly,
    /// calling the `onFocus` callback will set the `FocusState` to true, and the `onBlur` callback
    /// will set it to false.
    ///
    /// ## See Also
    /// [FocusBinding](x-source-tag://FocusBinding)
    ///
    public func binding() -> FocusBinding where Value == Bool {
        self[true]
    }
}

extension FocusState {
    @propertyWrapper
    private final class Storage {
        let defaultValue: Value
        var bindings: [Value: FocusBinding] = [:]

        init(wrappedValue initialValue: Value) {
            defaultValue = initialValue
            value = initialValue
        }

        var projectedValue: Storage {
            self
        }

        var wrappedValue: Value {
            get { value }
            set { value = newValue }
        }

        private var value: Value {
            didSet {
                guard oldValue != value else {
                    return
                }

                if oldValue != defaultValue, let binding = bindings[oldValue] {
                    binding.trigger.blur()
                }

                if value != defaultValue, let binding = bindings[value] {
                    binding.trigger.focus()
                }
            }
        }

        func binding(for value: Value) -> FocusBinding {
            if let binding = bindings[value] {
                return binding
            }

            let binding = FocusBinding(
                onFocus: { [weak self] in
                    self?.value = value
                },
                onBlur: { [weak self] in
                    if let self = self, self.value == value {
                        self.value = self.defaultValue
                    }
                }
            )

            bindings[value] = binding

            return binding
        }
    }
}
