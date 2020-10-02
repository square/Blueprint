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
public struct KeyboardReader : ProxyElement {
    
    /// Provides an element rendered with the provided keyboard information.
    public typealias ElementProvider = (KeyboardProxy) -> Element
    
    /// The provider which is called to generate a new element.
    public var provider : ElementProvider
    
    /// Creates a new instance of `KeyboardReader` that renders
    /// the provided element from the element provider.
    public init(_ provider : @escaping ElementProvider) {
        self.provider = provider
    }
    
    public static func adjustedForKeyboard(_ provider : @escaping ElementProvider) -> Self {
        self.init(
            background: { Empty() },
            adjustedForKeyboard: provider
        )
    }
    
    /// Creates a new instance of `KeyboardReader` that renders
    /// the provided element from the element provider.
    ///
    ///
    public init(
        background : @escaping () -> Element,
        adjustedForKeyboard : @escaping ElementProvider
    ) {
        self.provider = { info in
            Overlay { overlay in
                overlay.add(background())
                
                overlay.add {
                    adjustedForKeyboard(info).map { element in
                        switch info.keyboardFrame {
                        case .nonOverlapping:
                            return element
                            
                        case .overlapping(let frame):
                            return element.constrainedTo(height: .absolute(info.size.height - frame.height))
                        }
                    }
                }
            }
        }
    }
    
    public var elementRepresentation: Element {
        EnvironmentReader { environment in
            Content(environment: environment, provider: self.provider)
        }
    }
    
    /// Private element which is used to capture the `Environment` to
    /// pass through to the inner `BlueprintView`.
    private struct Content : Element {
        
        var environment : Environment
        var provider : ElementProvider
        
        public var content: ElementContent {
            ElementContent { constraint in
                                
                let element = self.provider(
                    .init(
                        keyboardFrame: .nonOverlapping,
                        size: constraint.maximum
                    )
                )
                
                return element.content.measure(in: constraint, environment: self.environment)
            }
        }
        
        public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
                        
            View.describe { config in
                config.apply { view in
                    
                    /// Pass all properties through to the view; then
                    /// force an update on the content via a layout pass.
                    
                    view.environment = self.environment
                    view.provider = self.provider
                    
                    view.setNeedsLayout()
                    view.layoutIfNeeded()
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
    public var keyboardFrame : KeyboardFrame
    
    /// The size of the element is using to lay out.
    public var size : CGSize
    
    public init(
        keyboardFrame: KeyboardFrame,
        size: CGSize
    ) {
        self.keyboardFrame = keyboardFrame
        self.size = size
    }
}


fileprivate extension KeyboardReader {
    
    final class View : UIView, KeyboardObserverDelegate {
        private let blueprintView : BlueprintView
        private let keyboardObserver : KeyboardObserver = .shared
        
        var environment : Environment = .empty {
            didSet {
                self.needsElementUpdate = true
            }
        }
        
        var provider : ElementProvider? = nil {
            didSet {
                self.needsElementUpdate = true
            }
        }
                
        override init(frame: CGRect) {
            
            self.blueprintView = BlueprintView()
            self.blueprintView.backgroundColor = .clear
            
            super.init(frame: frame)
            
            self.keyboardObserver.add(delegate: self)
            
            self.addSubview(self.blueprintView)
        }
        
        @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }
        
        private var lastKeyboardFrame : KeyboardFrame? = nil
        private var needsElementUpdate : Bool = true
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            self.blueprintView.frame = self.bounds
            
            let keyboardFrame = self.keyboardObserver.currentFrame(in: self)
            
            /// If the keyboard frame has changed; either due to the keyboard moving,
            /// or our view position changing, we should update the element.
            
            if keyboardFrame != self.lastKeyboardFrame || self.needsElementUpdate {
                self.needsElementUpdate = false
                self.lastKeyboardFrame = keyboardFrame
                
                self.updateElement(with: keyboardFrame)
            }
        }
        
        private func updateElement(with keyboardFrame : KeyboardFrame?) {
            
            self.blueprintView.inheritedEnvironment = self.environment
            
            self.blueprintView.element = self.provider?(
                KeyboardProxy(
                    keyboardFrame: keyboardFrame ?? .nonOverlapping,
                    size: self.bounds.size
                )
            )
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
