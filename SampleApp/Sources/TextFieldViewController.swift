//
//  TextFieldViewController.swift
//  SampleApp
//
//  Created by Kyle Van Essen on 4/15/20.
//  Copyright © 2020 Square. All rights reserved.
//

import UIKit
import BlueprintUI
import BlueprintUICommonControls


struct MarketTextField : ProxyElement {
        
    var isFirstResponder : Bool
    var label : String
    var data : String
    var placeholder : String
    
    var elementRepresentation: Element {
        Field(isFirstResponder: self.isFirstResponder) { state in
                        
            let content = ConstrainedSize(
                height: .atLeast(64.0),
                wrapping: Aligned(
                    vertically: .center,
                    horizontally: .leading,
                    wrapping: Inset(
                        insets: UIEdgeInsets(top: 10.0, left: 15.0, bottom: 10.0, right: 15.0),
                        wrapping: Column {
                            $0.horizontalAlignment = .fill
                            
                            let showsMainField = self.placeholder.isEmpty == false || self.data.isEmpty == false || state.info.isFirstResponder
                            
                            if showsMainField {
                                $0.add(key: AnyHashable("label"), child: Label(text: self.label) {
                                    $0.font = .systemFont(ofSize: 12.0, weight: .bold)
                                })
                                
                                $0.add(child: Spacer(size: .init(width: 0, height: 5)))
                                
                                $0.add(key: AnyHashable("field"), child: Label(text: self.label) {
                                    $0.font = .systemFont(ofSize: 16.0, weight: .regular)
                                    $0.color = .lightGray
                                })
                            } else {
                                $0.add(key: AnyHashable("label"), child: Label(text: self.label) {
                                    $0.font = .systemFont(ofSize: 16.0, weight: .regular)
                                    $0.color = .darkGray
                                })
                            }
                        }
                    )
                )
            )
            
            return Tappable(
                onTap: { state.becomeFirstResponder() },
                wrapping: content
            )
        }
    }
}




fileprivate struct Field : Element {
        
    typealias Provider = (State) -> Element
    
    var isFirstResponder : Bool
    
    var elementProvider : Provider
    
    init(isFirstResponder : Bool = false, elementProvider : @escaping Provider) {
        self.isFirstResponder = isFirstResponder
        self.elementProvider = elementProvider
    }
    
    var content: ElementContent {
        ElementContent {
            let state = State(
                info: .init(
                    isFirstResponder: false
                )
            )
            
            let content = self.elementProvider(state)
            
            return content.content.measure(in: $0)
        }
    }
    
    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        View.describe {
            $0.builder = {
                View(isFirstResponder: self.isFirstResponder, frame: bounds)
            }
            
            $0.apply {
                $0.elementProvider = self.elementProvider
            }
        }
        
    }
    
    final class State {
        
        var info : Info {
            didSet {
                guard self.info != oldValue else {
                    return
                }
                
                self.fieldView?.updateElement()
            }
        }
        
        weak var fieldView : View?
        
        struct Info : Equatable {
            var isFirstResponder : Bool
        }
        
        init(info : Info) {
            self.info = info
        }
        
        func becomeFirstResponder() {
            self.info.isFirstResponder.toggle()
        }
    }
    
    final class View : UIView {
        let blueprintView : BlueprintView
        
        let state : State
        
        var elementProvider : Provider? {
            didSet {
                self.updateElement()
            }
        }
        
        init(isFirstResponder : Bool, frame: CGRect) {
            self.blueprintView = BlueprintView()
            
            self.state = State(
                info: .init(
                    isFirstResponder: isFirstResponder
                )
            )
            
            super.init(frame: frame)
            
            self.state.fieldView = self
            
            self.addSubview(self.blueprintView)
            
            let notifications = [
                UITextField.textDidBeginEditingNotification,
                UITextField.textDidEndEditingNotification,
                
                UITextView.textDidBeginEditingNotification,
                UITextView.textDidEndEditingNotification,
            ]
                        
            notifications.forEach {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(firstResponderChanged),
                    name: $0,
                    object: nil
                )
            }
            
            self.updateElement()
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            self.blueprintView.frame = self.bounds
        }
        
        func updateElement() {
            guard let provider = self.elementProvider else {
                self.blueprintView.element = nil
                return
            }
            
            let contents = provider(self.state)
            
            self.blueprintView.element = Border(wrapping: contents)
        }
        
        @objc private func firstResponderChanged() {
            
        }
    }
    
    struct Border : ProxyElement {
                        
        var wrapping : Element
        
        init(wrapping element : Element) {
            self.wrapping = element
        }
        
        var elementRepresentation: Element {
            self.wrapping
        }
        
        func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
            View.describe { _ in }
        }
        
        private final class View : UIView {
            override init(frame: CGRect) {
                super.init(frame: frame)
                
                self.layer.borderWidth = 2.0
                self.layer.borderColor = UIColor.darkGray.cgColor
                self.layer.cornerRadius = 10.0
            }
            
            required init?(coder: NSCoder) { fatalError() }
        }
    }
}


private extension UIView
{
    func mkt_isViewInHierarchy(_ view : UIView) -> Bool
    {
        var superview = view.superview
        
        while superview != nil {
            if superview === self {
                return true
            }
            
            superview = superview?.superview
        }
        
        return false
    }
    
    func mkt_findFirstResponder() -> UIView?
    {
        if self.isFirstResponder {
            return self
        } else {
            for subview in self.subviews {
                if let firstResponder = subview.mkt_findFirstResponder() {
                    return firstResponder
                }
            }
        }
        
        return nil
    }
}


#if DEBUG && canImport(SwiftUI) && !arch(i386)

import SwiftUI

@available(iOS 13.0, *)
struct TextField_Preview: PreviewProvider {
    static var previews: some View {
        
        let size = ElementPreview.PreviewType.fixed(width: 300.0, height: 150.0)
        
        return ElementPreview(with: size) {
            MarketTextField(
                isFirstResponder: false,
                label: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer vitae elementum ex.",
                data: "",
                placeholder : ""
            )
        }
    }
}

#endif
