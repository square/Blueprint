//
//  KeyboardReader.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 9/30/20.
//

import Foundation


///
///
///
public struct KeyboardReader : ProxyElement {
    
    public typealias ElementProvider = (KeyboardProxy) -> Element
    
    public var provider : ElementProvider
    
    public init(_ provider : @escaping ElementProvider) {
        self.provider = provider
    }
    
    public var elementRepresentation: Element {
        EnvironmentReader { environment in
            Content(environment: environment, provider: self.provider)
        }
    }
    
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
                    view.environment = self.environment
                    view.provider = self.provider
                    
                    view.setNeedsLayout()
                    view.layoutIfNeeded()
                }
            }
        }
    }
}


///
///
///
public struct KeyboardProxy {
    public var keyboardFrame : KeyboardFrame
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
        private let keyboardObserver : KeyboardObserver
        
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
        
        private var lastKeyboardFrame : KeyboardFrame? = nil
        
        override init(frame: CGRect) {
            
            self.blueprintView = BlueprintView()
            self.keyboardObserver = KeyboardObserver()
            
            super.init(frame: frame)
            
            self.keyboardObserver.delegate = self
            
            self.addSubview(self.blueprintView)
        }
        
        @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }
        
        private var needsElementUpdate : Bool = true
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            self.blueprintView.frame = self.bounds
            
            let frame = self.keyboardObserver.currentFrame(in: self)
            
            if frame != self.lastKeyboardFrame || self.needsElementUpdate {
                self.needsElementUpdate = false
                self.lastKeyboardFrame = frame
                
                self.updateElement()
            }
        }
        
        private func updateElement() {
            let keyboardFrame = self.keyboardObserver.currentFrame(in: self)
            
            self.blueprintView.baseEnvironment = self.environment
            
            self.blueprintView.element = self.provider?(
                KeyboardProxy(
                    keyboardFrame: keyboardFrame ?? .nonOverlapping,
                    size: self.bounds.size
                )
            )
            .aligned(vertically: .top, horizontally: .center)
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
                },
                completion: nil
            )
        }
    }
}
