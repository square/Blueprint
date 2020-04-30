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
                
                self.contentView.element = provider(info)
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


fileprivate extension UIView {
    func findSubviews(passing : (UIView) -> Bool) -> [UIView] {
        var subviews = [UIView]()
        
        self.findSubviews(passing: passing, list: &subviews)
        
        return subviews
    }
    
    private func findSubviews(passing : (UIView) -> Bool, list : inout [UIView]) {
        
        if passing(self) {
            list.append(self)
        }
        
        for subview in self.subviews {
            subview.findSubviews(passing: passing, list: &list)
        }
    }
}
