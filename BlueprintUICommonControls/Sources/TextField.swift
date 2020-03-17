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

    public var becomeActiveTrigger: Trigger?
    public var resignActiveTrigger: Trigger?

    public init(text: String) {
        self.text = text
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return CallbackTextField.describe({ (configuration) in
            configuration[\.backgroundColor] = .clear

            configuration[\.text] = text
            configuration[\.placeholder] = placeholder
            configuration[\.onChange] = onChange
            configuration[\.isSecureTextEntry] = secure
            configuration[\.isEnabled] = isEnabled
            configuration[\.textAlignment] = textAlignment

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

            configuration[\.becomeActiveTrigger] = becomeActiveTrigger
            configuration[\.resignActiveTrigger] = resignActiveTrigger
        })
    }

    public var content: ElementContent {
        return ElementContent { constraint in
            return CGSize(
                width: max(constraint.maximum.width, 44),
                height: 44.0)
        }
    }
    
}

extension TextField {

    final public class Trigger {

        var action: () -> Void

        public init() {
            action = { }
        }

        public func fire() {
            action()
        }

    }

}


fileprivate final class CallbackTextField: UITextField, UITextFieldDelegate {
    
    var onChange: ((String) -> Void)? = nil
    var onReturn: (() -> Void)? = nil

    var becomeActiveTrigger: TextField.Trigger? {
        didSet {
            oldValue?.action = { }
            becomeActiveTrigger?.action = { [weak self] in self?.becomeFirstResponder() }
        }
    }

    var resignActiveTrigger: TextField.Trigger? {
        didSet {
            oldValue?.action = { }
            resignActiveTrigger?.action = { [weak self] in self?.resignFirstResponder() }
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

}
