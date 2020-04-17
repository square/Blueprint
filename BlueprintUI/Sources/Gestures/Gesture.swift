//
//  Gesture.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 4/16/20.
//

import Foundation


public struct Gesture<GestureType:UIGestureRecognizer> : ProxyElement {
    
    public typealias GestureProvider = () -> GestureType
    public typealias GestureChanged = (GestureType) -> ()
    
    public var gestureProvider : GestureProvider
    public var onChange : GestureChanged
    
    public var delegate : Delegate
    
    public var wrapped : Element
    
    public init(
        gesture gestureProvider : @escaping GestureProvider,
        onChange : @escaping GestureChanged,
        delegate : Delegate = Delegate(),
        wrapping : Element
    ) {
        
        self.gestureProvider = gestureProvider
        self.onChange = onChange
        
        self.delegate = delegate
        
        self.wrapped = wrapping
    }
    
    // MARK: ProxyElement
    
    public var elementRepresentation: Element {
        self.wrapped
    }
    
    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        ViewDescription(View.self) {
            $0.builder = {
                View(
                    frame: bounds,
                    delegate: self.delegate,
                    onChange:self.onChange,
                    gestureProvider: self.gestureProvider
                )
            }
            
            $0.apply {
                $0.delegate.delegate = self.delegate
                $0.onChange = self.onChange
            }
        }
    }
    
    public struct Delegate {
        
        public init() {}
        
        public var shouldBegin : ((_ gestureRecognizer: GestureType) -> Bool)? = nil
        
        public var shouldRecognizeSimultaneouslyWith : ((_ gestureRecognizer: GestureType, _ otherGestureRecognizer: UIGestureRecognizer) -> Bool)? = nil

        public var shouldRequireFailureOf : ((_ gestureRecognizer: GestureType, _ otherGestureRecognizer: UIGestureRecognizer) -> Bool)? = nil

        public var shouldBeRequiredToFailBy : ((_ gestureRecognizer: GestureType, _ otherGestureRecognizer: UIGestureRecognizer) -> Bool)? = nil

        public var shouldReceiveTouch : ((_ gestureRecognizer: GestureType, _ touch: UITouch) -> Bool)? = nil

        public var shouldReceivePress : ((_ gestureRecognizer: GestureType, _ press: UIPress) -> Bool)? = nil

        public var shouldReceiveEvent : ((_ gestureRecognizer: GestureType, _ event: UIEvent) -> Bool)? = nil
        
        fileprivate final class Implementation : NSObject, UIGestureRecognizerDelegate {
            
            var delegate : Delegate
            
            init(delegate : Delegate) {
                self.delegate = delegate
            }
            
            /// Only report that we conform to these methods if the `Delegate` struct has a closure for each method,
            /// to ensure that we maintain the default behavior that occurs when there is no delegate implementation.
            override func responds(to sel: Selector!) -> Bool {
                if sel == #selector(gestureRecognizerShouldBegin(_:)) {
                    return self.delegate.shouldBegin != nil
                } else if sel == #selector(gestureRecognizer(_:shouldRecognizeSimultaneouslyWith:)) {
                    return self.delegate.shouldRecognizeSimultaneouslyWith != nil
                } else if sel == #selector(gestureRecognizer(_:shouldRequireFailureOf:)) {
                    return self.delegate.shouldRequireFailureOf != nil
                } else if sel == #selector(gestureRecognizer(_:shouldBeRequiredToFailBy:)) {
                    return self.delegate.shouldBeRequiredToFailBy != nil
                } else if sel == #selector(gestureRecognizer(_:shouldReceive:) as (UIGestureRecognizer, UITouch) -> Bool) {
                    return self.delegate.shouldReceiveTouch != nil
                } else if sel == #selector(gestureRecognizer(_:shouldReceive:) as (UIGestureRecognizer, UIPress) -> Bool) {
                    return self.delegate.shouldReceivePress != nil
                } else if sel == #selector(gestureRecognizer(_:shouldReceive:) as (UIGestureRecognizer, UIEvent) -> Bool) {
                    return self.delegate.shouldReceiveEvent != nil
                } else {
                    return super.responds(to: sel)
                }
            }
            
            func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
                self.delegate.shouldBegin!(gestureRecognizer as! GestureType)
            }
            
            func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
                self.delegate.shouldRecognizeSimultaneouslyWith!(gestureRecognizer as! GestureType, otherGestureRecognizer)
            }

            func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
                self.delegate.shouldRequireFailureOf!(gestureRecognizer as! GestureType, otherGestureRecognizer)
            }

            func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
                self.delegate.shouldBeRequiredToFailBy!(gestureRecognizer as! GestureType, otherGestureRecognizer)
            }

            func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
                self.delegate.shouldReceiveTouch!(gestureRecognizer as! GestureType, touch)
            }

            func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive press: UIPress) -> Bool {
                self.delegate.shouldReceivePress!(gestureRecognizer as! GestureType, press)
            }

            func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive event: UIEvent) -> Bool {
                self.delegate.shouldReceiveEvent!(gestureRecognizer as! GestureType, event)
            }
        }
    }
    
    fileprivate final class View : UIView {
                
        let gesture : GestureType
        
        var delegate : Delegate.Implementation
        var onChange : GestureChanged
        
        init(frame : CGRect, delegate : Delegate, onChange : @escaping GestureChanged, gestureProvider : @escaping GestureProvider) {
            
            self.delegate = Delegate.Implementation(delegate: delegate)
                        
            self.gesture = gestureProvider()
            self.gesture.delegate = self.delegate
            
            self.onChange = onChange
            
            super.init(frame: frame)
                        
            self.addGestureRecognizer(self.gesture)
            
            self.gesture.addTarget(self, action: #selector(gestureStateChanged))
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        @objc func gestureStateChanged() {
            self.onChange(self.gesture)
        }
    }

}
