//
//  Stateful.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 4/16/20.
//

import Foundation


public struct Stateful<Value> : Element {
    
    public typealias Provider = (State) -> Element
    
    public var initial : Value
    public var provider : Provider
    
    public init(initial value : Value, element : @escaping Provider) {
        self.initial = value
        self.provider = element
    }
    
    public var content : ElementContent {
        
        /// TODO: Right now this ends up being based on the initial state... not the current
        /// state as presented in the UI.
        
        ElementContent {
            let state = State(value: self.initial)
            let element = self.provider(state)
            
            return element.content.measure(in: $0)
        }
    }
    
    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        ViewDescription(View.self) {
            $0.builder = {
                View(frame: bounds, value: self.initial, provider: self.provider)
            }
        }
    }
    
    public final class State {
        
        var onChange : () -> ()
        
        public var value : Value {
            didSet {
                self.onChange()
            }
        }
        
        public func set(_ update : (inout Value) -> ()) {
            var new = self.value
            
            update(&new)
            
            self.value = new
        }
        
        init(value : Value, onChange : @escaping () -> () = {}) {
            self.value = value
            self.onChange = onChange
        }
    }
    
    private final class View : UIView {
        
        let provider : Provider
        
        let view : BlueprintView
        
        let state : State
        
        init(frame: CGRect, value : Value, provider : @escaping Provider) {
            
            self.provider = provider
            
            self.view = BlueprintView(frame: CGRect(origin: .zero, size: frame.size))
            
            self.state = State(value: value)
            
            super.init(frame: frame)
            
            self.addSubview(self.view)
            
            self.state.onChange = { [weak self] in
                self?.updateElement(updateParentBlueprintViews: true)
            }
            
            self.updateElement()
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            self.view.frame = self.bounds
        }
        
        private func updateElement(updateParentBlueprintViews update : Bool = false) {
            self.view.element = self.provider(self.state)
            
            if update {
                var superview : UIView? = self.superview
                
                while superview != nil {
                    if let blueprintView = superview as? BlueprintView {
                        blueprintView.setNeedsViewHierarchyUpdate()
                    }
                    
                    superview = superview?.superview
                }
            }
        }
    }
}

