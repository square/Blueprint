//
//  ElementStateTree.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 6/24/21.
//

import Foundation


public final class ElementStateTree : CustomDebugStringConvertible {
    
    private var states : [ElementIdentifier:ElementState] = [:]
    
    func state(for element : Element, with identifier : ElementIdentifier) -> ElementState {
        if let existing = self.states[identifier] {
            return existing
        } else {
            let new = ElementState(identifier: identifier, element: element)
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


extension ElementStateTree {
    
    final class ElementState {
        
        var state : Any? = nil
        
        var identifier : ElementIdentifier
        var element : Element
        
        var children : ElementStateTree = .init()
        
        init(identifier : ElementIdentifier, element : Element) {
            self.identifier = identifier
            self.element = element
        }
        
        func setup() {
            
        }
        
        func teardown() {
            
        }
        
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
}
