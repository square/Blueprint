//
//  KeyboardAdjusting.swift
//  BlueprintUICommonControls
//
//  Created by Kyle Van Essen on 4/28/20.
//

import BlueprintUI
import UIKit


public struct KeyboardAdjusting : Element {
    
    public typealias Provider = (Info) -> Content
    
    public struct Info : Equatable {
        public var size : CGSize
        public var keyboardInset : CGFloat
    }
    
    public struct Content {
        public var element : Element
        public var inputAccessory : Element?
        
        public init(element : Element, inputAccessory : Element? = nil) {
            self.element = element
            self.inputAccessory = inputAccessory
        }
    }
    
    public var provider : Provider
    
    public init(provider : @escaping Provider) {
        self.provider = provider
    }
    
    public var content: ElementContent {
        ElementContent {
            $0.maximum
        }
    }
    
    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        View.describe {
            $0.apply {
                $0.provider = self.provider
            }
        }
    }
    
    private final class View : UIView, KeyboardObserverDelegate {
        let contentView : BlueprintView
        
        let keyboardObserver : KeyboardObserver
        
        var provider : Provider? {
            didSet {
                self.updateElement()
            }
        }
        
        override init(frame: CGRect) {
            self.contentView = BlueprintView()
            
            self.keyboardObserver = KeyboardObserver()
            
            super.init(frame: frame)
            
            self.keyboardObserver.delegate = self
            
            self.addSubview(self.contentView)
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        private var keyboardInset : CGFloat = 0.0
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            if self.contentView.frame != self.bounds {
                self.contentView.frame = self.bounds
                self.updateElement()
            }
        }
        
        override var canBecomeFirstResponder: Bool {
            return true
        }
        
        private var inputAccessoryBlueprintView : BlueprintView = BlueprintView()
        
        override var inputAccessoryView: UIView? {
            return self.inputAccessoryBlueprintView
        }
        
        override func willMove(toSuperview newSuperview: UIView?) {
            super.willMove(toSuperview: newSuperview)
            
            self.becomeFirstResponder()
        }
        
        private var lastInfo : Info? = nil
        
        func updateElement() {
            guard let provider = self.provider else {
                self.contentView.element = nil
                
                return
            }
            
            let info = Info(
                size: self.contentView.bounds.size,
                keyboardInset: self.keyboardInset
            )
                        
            if self.lastInfo != info {
                self.lastInfo = info
                
                let content = provider(info)
                
                self.contentView.element = content.element
                self.inputAccessoryBlueprintView.element = content.inputAccessory
                self.inputAccessoryBlueprintView.frame.size = self.inputAccessoryBlueprintView.sizeThatFits(CGSize(width: UIScreen.main.bounds.width, height: .greatestFiniteMagnitude))
            }
        }
        
        // MARK: KeyboardObserverDelegate
        
        func keyboardFrameWillChange(
            for observer : KeyboardObserver,
            duration : Double,
            options : UIView.AnimationOptions
        ) {
            self.keyboardInset = self.bottomInset(for: observer)
            
            UIView.animate(withDuration: duration, delay: 0.0, options: options, animations: {
                self.setNeedsLayout()
                self.updateElement()
                self.layoutIfNeeded()
            })
        }
        
        func bottomInset(for observer : KeyboardObserver) -> CGFloat {
            guard let keyboardFrame = self.keyboardObserver.currentFrame(in: self) else {
                return 0.0
            }
            
            switch keyboardFrame {
            case .nonOverlapping: return 0.0
            case .overlapping(let frame, _): return self.bounds.size.height - frame.origin.y
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
    
    init(style : Style, wrapping : () -> Element) {
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
        
        let contentView : UIInputView? = nil
        let blueprintView : BlueprintView
        
        init(style : Style, frame: CGRect, wrapping : Element) {
            
            self.style = style
            self.wrapped = wrapping
            
            let bounds = CGRect(origin: .zero, size: frame.size)
            
            self.blueprintView = BlueprintView(frame: bounds)
            self.blueprintView.element = wrapping
            
            super.init(frame: frame)
            
            self.updatedStyle(to: self.style)
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            self.inputView?.frame = self.bounds
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
            } else {
                self.addSubview(self.blueprintView)
            }
        }
    }
}
