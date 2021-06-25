//
//  State.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 6/24/21.
//

import Foundation


protocol AnyElementState {
    
    var anyLive : AnyElementStateLiveState? { get }
    
}

protocol AnyElementStateLiveState : AnyObject {
    
}

@propertyWrapper public struct ElementState<State> : AnyElementState {
    
    public var wrappedValue : State {
        get {
            self.live?.current ?? self.original
        }
        
        nonmutating set {
            self.live?.current = newValue
        }
    }
    
    let original : State
    let live : LiveState? = nil
    
    public init(wrappedValue : State) {
        self.original = wrappedValue
    }
    
    final class LiveState : AnyElementStateLiveState {
        var current : State {
            didSet {
                
            }
        }
        
        init(current : State) {
            self.current = current
        }
    }
    
    // MARK: AnyElementState
    
    var anyLive: AnyElementStateLiveState? {
        self.live
    }
}


public protocol StatefulElement : Element {}


public struct Stateful<State> : StatefulElement {
    
    @ElementState public var state : State
    
    public typealias ElementProvider = (State) -> Element
    
    public let initial : () -> State
    public let provider : ElementProvider
    
    public init(_ initial : @escaping @autoclosure () -> State, provider : @escaping ElementProvider) {
        _state = .init(wrappedValue: initial())
        
        self.initial = initial
        self.provider = provider
    }
    
    public var content: ElementContent {
        fatalError()
    }
    
    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        View.describe { _ in }
    }
    
    private final class View : UIView {
        
        
    }
}

extension StatefulElement {
    
    func allStateProperties() {
        let mirror = Mirror(reflecting: self)
        
        for property in mirror.children {
            if let state = property.value as? AnyElementState {
                print("Found stateful property \(property.label ?? "[No Name]"): \(property.value )")
            }
        }
    }
    
}
