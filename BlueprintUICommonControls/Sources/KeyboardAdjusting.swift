//
//  KeyboardAdjusting.swift
//  BlueprintUICommonControls
//
//  Created by Kyle Van Essen on 4/28/20.
//

import BlueprintUI
import UIKit


public struct InputAccessoryScreen : Element {
    
    public var wrapped : Element
    public var inputAccessory : InputAccessory?
    
    public init(
        wrapping : Element,
        inputAccessory : InputAccessory? = nil
    ) {
        self.wrapped = wrapping
        self.inputAccessory = inputAccessory
    }
    
    public var content: ElementContent {
        ElementContent {
            $0.maximum
        }
    }
    
    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        View.describe {
            $0.apply {
                $0.wrapped = self.wrapped
                $0.inputAccessory = self.inputAccessory
            }
        }
    }
    
    private final class View : UIView {
        
        private let contentView : BlueprintView
        private let accessoryView : InputAccessoryView
                
        public var wrapped : Element? = nil {
            didSet {
                self.contentView.element = self.wrapped
            }
        }
        
        public var inputAccessory : InputAccessory? = nil {
            didSet {
                self.accessoryView.element = self.inputAccessory
            }
        }
        
        override init(frame: CGRect) {
            self.contentView = BlueprintView()
            self.accessoryView = InputAccessoryView()
            
            super.init(frame: frame)
                        
            self.addSubview(self.contentView)
        }
        
        required init?(coder: NSCoder) { fatalError() }
             
        override func layoutSubviews() {
            super.layoutSubviews()
            
            self.contentView.frame = self.bounds
        }
        
        override var canBecomeFirstResponder: Bool {
            return true
        }
                
        override var inputAccessoryView : UIView {
            self.accessoryView
        }
        
        override func willMove(toSuperview newSuperview: UIView?) {
            super.willMove(toSuperview: newSuperview)
            
            self.becomeFirstResponder()
        }
    }
    
    private final class InputAccessoryView : UIView {
        
        var element : Element? {
            didSet {
                self.contentView.element = element
                
                if let element = self.element, self.frame.size == .zero {
                    self.frame.size = element.content.measure(in: .init(width: UIScreen.main.bounds.width))
                }
                
                self.contentView.layoutIfNeeded()
                self.contentView.invalidateIntrinsicContentSize()
            }
        }
        
        private let contentView : BlueprintView
        
        override init(frame: CGRect) {
            let bounds = CGRect(origin: .zero, size: frame.size)
            
            self.contentView = BlueprintView(frame: bounds)
            self.contentView.backgroundColor = .clear
            
            super.init(frame: frame)
            
            self.addSubview(self.contentView)
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            self.contentView.frame = self.bounds
        }
        
        override func sizeThatFits(_ size: CGSize) -> CGSize {
            self.contentView.sizeThatFits(size)
        }
        
        override var intrinsicContentSize: CGSize {
            if let element = self.contentView.element {
                let size = element.content.measure(in: SizeConstraint(width: UIScreen.main.bounds.width))
                print(size)
                return size
            } else {
                return .zero
            }
        }
    }
}


public struct InputAccessory : Element {
    
    public var style : Style
    
    public var wrapped : Element
        
    public enum Style : Equatable {
        case none
        case `default`
        case keyboard
        
        fileprivate var inputViewStyle : UIInputView.Style? {
            switch self {
            case .none: return nil
            case .default: return .default
            case .keyboard: return .keyboard
            }
        }
    }
    
    public init(style : Style, wrapping : () -> Element) {
        self.style = style
        self.wrapped = wrapping()
    }
    
    public var content: ElementContent {
        ElementContent {
            self.wrapped.content.measure(in: $0)
        }
    }
    
    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        View.describe {
            $0.builder = {
                View(style: self.style, frame: bounds, wrapping: self.wrapped)
            }
            
            $0.apply {
                $0.style = self.style
                $0.wrapped = self.wrapped
            }
        }
    }
    
    final class View : UIView {
        var style : Style {
            didSet {
                guard oldValue != self.style else {
                    return
                }
                
                self.updatedStyle(to: self.style)
            }
        }
        
        var wrapped : Element {
            didSet {
                self.blueprintView.element = self.wrapped
            }
        }
        
        private var contentView : UIInputView? = nil
        private let blueprintView : BlueprintView
        
        init(style : Style, frame: CGRect, wrapping : Element) {
            
            self.style = style
            self.wrapped = wrapping
            
            let bounds = CGRect(origin: .zero, size: frame.size)
            
            self.blueprintView = BlueprintView(frame: bounds)
            self.blueprintView.backgroundColor = .clear
            self.blueprintView.element = wrapping
            
            super.init(frame: frame)
            
            self.updatedStyle(to: self.style)
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            self.contentView?.frame = self.bounds
            self.blueprintView.frame = self.bounds
        }
        
        private func updatedStyle(to new : Style) {
            self.blueprintView.removeFromSuperview()
            
            if let inputView = self.contentView {
                inputView.removeFromSuperview()
            }
            
            if let style = self.style.inputViewStyle {
                let inputView = UIInputView(frame: self.bounds, inputViewStyle: style)
                inputView.addSubview(self.blueprintView)
                self.addSubview(inputView)
                
                self.contentView = inputView
            } else {
                self.addSubview(self.blueprintView)
            }
        }
    }
}
