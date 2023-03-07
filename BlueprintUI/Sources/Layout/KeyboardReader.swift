//
//  KeyboardReader.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 9/30/20.
//

import Foundation


///
/// A `KeyboardReader` is used to build an element which is responsive to the position of
/// the on-screen iOS keyboard. This allows you to customize your elements based on the
/// state of the on-screen keyboard.
///
/// While Blueprint's `ScrollView` already adjusts insets for the keyboard, other custom
/// elements and UIs do not. Use a `KeyboardReader` to implement keyboard management
/// within your element.
///
/// The initializer for `KeyboardReader` takes an escaping closure, which is called each time
/// the keyboard frame changes, or the element's frame changes, in order to update the element
/// to account for the new keyboard position.
///
/// ```
/// KeyboardReader { info in
///     myElement.inset(bottom: info.keyboardFrame.height)
/// }
/// ```
public struct KeyboardReader: Element {

    /// Provides an element rendered with the provided keyboard information.
    public typealias ElementProvider = (KeyboardProxy) -> Element

    /// The provider which is called to generate a new element.
    public var provider: ElementProvider

    /// Creates a new instance of `KeyboardReader` that renders
    /// the provided element from the element provider.
    public init(_ provider: @escaping ElementProvider) {
        self.provider = provider
    }

    // MARK: Element

    public var content: ElementContent {
        ElementContent { constraint, env in
            provider(.init(keyboardFrame: .nonOverlapping, layoutSize: constraint.maximum))
                .content
                .measure(in: constraint, environment: env)
        }
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {

        View.describe { config in
            config.apply { view in

                /// Pass all properties through to the view; then
                /// force an update on the content via a layout pass.

                view.provider = self.provider

                view.setNeedsLayout()
                view.layoutIfNeeded()
            }
        }
    }
}


extension KeyboardReader {

    /// Creates a new instance of `KeyboardReader` that renders
    /// the provided element from the element provider. This element will
    /// automatically adjust the `adjustedForKeyboard` element to
    /// account for the keyboard.
    public init(
        background: () -> Element = { Empty() },
        adjustedForKeyboard: @escaping ElementProvider
    ) {
        let background = background()

        provider = { proxy in
            Overlay {
                background

                adjustedForKeyboard(proxy).map { element in

                    let keyboardFrame: CGRect = proxy.keyboardFrame.frame ?? .zero

                    return element
                        .constrainedTo(height: .absolute(proxy.layoutSize.height - keyboardFrame.height))
                        .aligned(vertically: .top, horizontally: .fill)
                }
            }
        }
    }
}


/// Provides relevant information about the keyboard and view state
/// for you to use to adjust your provided element to account for the current
/// position of the keyboard.
public struct KeyboardProxy {

    /// The current frame of the keyboard.
    public var keyboardFrame: KeyboardFrame

    /// The size of the element is using to lay out.
    public var layoutSize: CGSize

    public init(
        keyboardFrame: KeyboardFrame,
        layoutSize: CGSize
    ) {
        self.keyboardFrame = keyboardFrame
        self.layoutSize = layoutSize
    }
}


extension Element {

    public func floatingAboveKeyboard(_ element: () -> Element) -> Element {

        let element = element()

        return KeyboardReader {
            self
                .adaptedEnvironment(
                    keyPath: \.floatingAboveKeyboardAccessoryFrame,
                    value: element.content.measure(in: <#T##SizeConstraint#>, environment: <#T##Environment#>)
                )
        } adjustedForKeyboard: { proxy in
            element.aligned(vertically: .bottom, horizontally: .fill)
        }
    }
}


extension Environment {

    public internal(set) var keyboardFrame: KeyboardFrame? {
        get { self[KeyboardFrameKey.self] }
        set { self[KeyboardFrameKey.self] = newValue }
    }

    public internal(set) var floatingAboveKeyboardAccessoryFrame: CGRect? {
        get { self[FloatingAboveKeyboardAccessoryFrameKey.self] }
        set { self[FloatingAboveKeyboardAccessoryFrameKey.self] = newValue }
    }

    private enum KeyboardFrameKey: EnvironmentKey {
        static let defaultValue: KeyboardFrame? = nil
    }

    private enum FloatingAboveKeyboardAccessoryFrameKey: EnvironmentKey {
        static let defaultValue: CGRect? = nil
    }
}


extension KeyboardReader {

    fileprivate final class View: UIView, KeyboardObserverDelegate {

        private let blueprintView: BlueprintView
        private let keyboardObserver: KeyboardObserver = .shared

        var provider: ElementProvider? = nil {
            didSet {
                self.needsElementUpdate = true
            }
        }

        override init(frame: CGRect) {

            blueprintView = BlueprintView()
            blueprintView.backgroundColor = .clear

            super.init(frame: frame)

            keyboardObserver.add(delegate: self)

            addSubview(blueprintView)
        }

        @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }

        private var lastKeyboardFrame: KeyboardFrame? = nil
        private var needsElementUpdate: Bool = true

        override func layoutSubviews() {
            super.layoutSubviews()

            blueprintView.frame = bounds

            let keyboardFrame = keyboardObserver.currentFrame(in: self)

            /// If the keyboard frame has changed; either due to the keyboard moving,
            /// or our view position changing, we should update the element.

            if keyboardFrame != lastKeyboardFrame || needsElementUpdate {
                needsElementUpdate = false
                lastKeyboardFrame = keyboardFrame

                updateElement(with: keyboardFrame)
            }
        }

        private func updateElement(with keyboardFrame: KeyboardFrame?) {

            let proxy = KeyboardProxy(
                keyboardFrame: keyboardFrame ?? .nonOverlapping,
                layoutSize: bounds.size
            )

            blueprintView.environment.keyboardFrame = keyboardFrame

            blueprintView.element = provider?(proxy)
        }

        // MARK: KeyboardObserverDelegate

        func keyboardFrameWillChange(
            for observer: KeyboardObserver,
            animationDuration: Double,
            options: UIView.AnimationOptions
        ) {
            UIView.animate(
                withDuration: animationDuration,
                delay: 0,
                options: options,
                animations: {
                    self.setNeedsLayout()
                    self.layoutIfNeeded()
                }
            )
        }
    }
}
