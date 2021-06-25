//
//  ElementStateTree.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 6/24/21.
//

import Foundation


public final class ElementStateTree {
    
    private var states : [ElementIdentifier:ElementState] = [:]
    
    func state(for element : Element, with identifier : ElementIdentifier) -> ElementState {
        if let existing = self.states[identifier] {
            return existing
        } else {
            let new = ElementState(element: element)
            new.setup()
            
            self.states[identifier] = new
            return new
        }
    }
    
    func removedOldStates(keeping liveIdentifiers : Set<ElementIdentifier>) {
        
        let removed = Set(self.states.keys).subtracting(liveIdentifiers)
        
        removed.forEach {
            let state = self.states[$0]
            
            // Ensures that all of the child states which are going away are removed as well.
            state?.children.removeAll()
            
            state?.teardown()
            
            self.states.removeValue(forKey: $0)
        }
    }
    
    func removeAll() {
        self.removedOldStates(keeping: [])
    }
}


extension ElementStateTree {
    
    final class ElementState {
        
        var state : Any? = nil
        
        var children : ElementStateTree = .init()
        
        init(element : Element) {
            
        }
        
        func setup() {
            
        }
        
        func teardown() {
            
        }
    }
}
