//
//  Button.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 12/15/20.
//

import UIKit


public struct Button : Element {
    
    public typealias OnTap = () -> ()
    public typealias ContentProvider = (State) -> Content
    
    public var onTap : OnTap
    
    public var contentProvider : ContentProvider
    
    public init(
        onTap : @escaping OnTap,
        content : @escaping ContentProvider
    ) {
        self.onTap = onTap
        self.contentProvider = content
    }
    
    public var content: ElementContent {
        ElementContent { constraint in
            
            let content = self.contentProvider(.normal)
            
            return content.element.content.measure(in: constraint, environment: .empty)
        }
    }
    
    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        ViewDescription(View.self) { config in
            config.builder = {
                View(model: self, frame: bounds)
            }
            
            config[\.model] = self
        }
    }
}


extension Button {
        
    public struct Content {
        public var element : Element
        public var accessibility : Accessibility
        
        public init(
            element : () -> Element,
            accessibility : () -> Accessibility
        ) {
            self.element = element()
            self.accessibility = accessibility()
        }
    }
    
    public struct Accessibility : Equatable {
        
        public var label : String?
        public var hint : String?
        public var value : String?
        
        public var traits : UIAccessibilityTraits?
        
        public init(
            label: String? = nil,
            hint: String? = nil,
            value: String? = nil
        ) {
            self.label = label
            self.hint = hint
            self.value = value
        }
        
        func apply(to control : UIControl) {
            
            if let label = self.label {
                control.accessibilityLabel = label
            }
            
            if let hint = self.hint {
                control.accessibilityHint = hint
            }
            
            if let value = self.value {
                control.accessibilityValue = value
            }
        }
    }
    
    public enum State : Equatable {
        case disabled
        case normal
        case highlighted
    }
}


extension Button {
    
    fileprivate final class View : UIControl {
        
        private let blueprintView : BlueprintView
        
        fileprivate var model : Button {
            didSet {
                self.updateFromModelIfNeeded()
            }
        }
        
        init(model : Button, frame: CGRect) {
            
            self.model = model
            
            self.blueprintView = BlueprintView()
            self.blueprintView.backgroundColor = .clear
            self.blueprintView.isUserInteractionEnabled = false
            
            self.lastState = .normal
            
            super.init(frame: frame)
                        
            self.addSubview(self.blueprintView)
            
            self.addTarget(self, action: #selector(onTouchUpInside), for: .touchUpInside)
            self.addTarget(self, action: #selector(onTouchDown), for: .touchDown)
            
            self.updateFromModel()
        }
        
        @available(*, unavailable) override init(frame: CGRect) { fatalError() }
        @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            self.blueprintView.frame = self.bounds
        }
        
        private var lastState : Button.State
        
        private func updateFromModelIfNeeded() {
            let new = self.currentState()
            
            guard self.lastState != new else {
                return
            }
            
            self.lastState = new
            
            self.updateFromModel()
        }
        
        private func updateFromModel() {
                                    
            let content = self.model.contentProvider(self.currentState())
            
            self.blueprintView.element = content.element
            
            content.accessibility.apply(to: self)
        }
        
        @objc private func onTouchUpInside() {
            self.isHighlighted = false
            
            self.updateFromModelIfNeeded()
            self.model.onTap()
        }

        @objc private func onTouchDown() {
            self.updateFromModelIfNeeded()
        }
        
        private func currentState() -> Button.State {
            if self.isEnabled {
                if self.isHighlighted {
                    return .highlighted
                } else {
                    return .normal
                }
            } else {
                return .disabled
            }
        }
    }
}
