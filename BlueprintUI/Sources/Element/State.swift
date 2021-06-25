//
//  State.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 6/24/21.
//

import Foundation



public struct Stateful<State> : Element {
    
    public typealias ElementProvider = (State) -> Element
    
    public let initial : () -> State
    public let provider : ElementProvider
    
    var liveState : LiveState?
    
    public init(_ initial : @escaping @autoclosure () -> State, provider : @escaping ElementProvider) {
        self.initial = initial
        self.provider = provider
    }
    
    public var content: ElementContent {
        if let liveState = self.liveState {
            return ElementContent(child: liveState.element)
        } else {
            return ElementContent(child: self.provider(self.initial()))
        }
    }
    
    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        View.describe { _ in }
    }
    
    private final class View : UIView {
        
        
    }
    
    final class LiveState {
        
//        var state : State {
//            didSet {
//
//            }
//        }
//
//        var element : Element
    }
}
