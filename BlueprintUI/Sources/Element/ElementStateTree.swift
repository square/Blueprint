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
            let new = ElementState(identifier: identifier, element: element)
            
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
        
        let identifier : ElementIdentifier
        var element : Element
        
        private(set) var liveState : [AnyElementStateLiveState] = []
        
        var children : ElementStateTree = .init()
        
        init(identifier : ElementIdentifier, element : Element) {
            self.identifier = identifier
            self.element = element
            
            if let stateful = element as? StatefulElement {
                stateful.bind(to: self)
            }
        }
        
        func setup(with properties : [AnyElementState]) {
            self.liveState = properties.map { $0.makeAndBindLiveState() }
        }
        
        func teardown() {
            
        }
    }
}







//
// MARK: CustomDebugStringConvertible
//


extension ElementStateTree : CustomDebugStringConvertible {
    
    public var debugDescription: String {
        
        var debugRepresentations = [ElementState.DebugRepresentation]()
        
        self.states.values.forEach {
            $0.appendDebugDescriptions(to: &debugRepresentations, at: 0)
        }
        
        let strings : [String] = debugRepresentations.map { child in
            Array(repeating: "  ", count: child.depth).joined() + "\(type(of:child.element)) #\(child.identifier.count)"
        }
        
        return strings.joined(separator: "\n")
    }
}


extension ElementStateTree.ElementState {
    
    
    func appendDebugDescriptions(to : inout [DebugRepresentation], at depth: Int) {
        to.append(DebugRepresentation(depth: depth, identifier: self.identifier, element:self.element))
        
        self.children.states.values.forEach { child in
            child.appendDebugDescriptions(to: &to, at: depth + 1)
        }
    }
    
    struct DebugRepresentation {
        var depth : Int
        var identifier : ElementIdentifier
        var element : Element
    }
}
