//
//  KeyboardAdjusting.swift
//  BlueprintUICommonControls
//
//  Created by Kyle Van Essen on 4/28/20.
//

import BlueprintUI
import UIKit


public struct KeyboardAdjusting : Element {
    
    public typealias Provider = (Info) -> Element
    
    public struct Info : Equatable {
        public var size : CGSize
        public var keyboardInset : CGFloat
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
        
//        private var addedContentOffset : CGFloat = 0.0
//
//        func updateContentOffset() {
//            let scrollViews = self.findSubviews {
//                $0 is UIScrollView
//            }
//
//            guard let scrollView = scrollViews.first as? UIScrollView else {
//                return
//            }
//
//            let offsetToAdd = self.keyboardInset - self.addedContentOffset
//
//            scrollView.contentOffset.y += offsetToAdd
//
//            self.addedContentOffset += offsetToAdd
//        }
        
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
