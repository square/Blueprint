//
//  State.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 6/24/21.
//

import Foundation


protocol AnyElementState {
    
    func makeAndBindLiveState() -> AnyElementStateLiveState
    
}

protocol AnyElementStateLiveState : AnyObject {
    
}

@propertyWrapper public struct ElementState<State> : AnyElementState {
    
    public var wrappedValue : State {
        get {
            self.live.value?.current ?? self.original
        }
        
        nonmutating set {
            self.live.value?.current = newValue
        }
    }
    
    public var projectedValue : Binding {
        Binding(live: self.live.value!)
    }
    
    let original : State
    let live : Box<LiveState?> = Box(nil)
    
    public init(wrappedValue : State) {
        self.original = wrappedValue
    }
    
    public struct Binding {
        var live : LiveState
        
        public var value : State {
            get {
                live.current
            }
            
            nonmutating set {
                live.current = newValue
            }
        }
    }
    
    final class LiveState : AnyElementStateLiveState {
        var current : State {
            didSet {
                print("Did set \(self.current)")
            }
        }
        
        init(current : State) {
            self.current = current
        }
    }
    
    // MARK: AnyElementState
    
    func makeAndBindLiveState() -> AnyElementStateLiveState {
        let live = LiveState(current: self.original)
        self.live.value = live
        
        return live
    }
}


final class Box<Value> {
    var value : Value
    
    init(_ value : Value) {
        self.value = value
    }
}


public protocol StatefulElement : Element {}


extension StatefulElement {
    
    func bind(to state : ElementStateTree.ElementState) {
        
        let mirror = Mirror(reflecting: self)
        
        let properties : [AnyElementState] = mirror.children.compactMap { property in
            guard let state = property.value as? AnyElementState else {
                return nil
            }
            
            return state
        }
        
        state.setup(with: properties)
    }
}
