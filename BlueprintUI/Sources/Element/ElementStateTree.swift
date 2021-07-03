//
//  ElementStateTree.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 6/24/21.
//

import Foundation


final class RootElementState {
    
    private(set) var root : ElementState?
    
    func update(with element : Element?) {
        
        if self.root == nil, let element = element {
            self.root = ElementState(
                identifier: .init(elementType: type(of: element), key: nil, count: 1),
                element: element
            )
        } else if let root = self.root, element == nil {
            root.teardown()
            self.root = nil
        } else if let root = self.root, let element = element {
            if type(of: root) == type(of: element) {
                root.update(with: element, identifier: root.identifier)
            } else {
                root.teardown()
                
                self.root = ElementState(
                    identifier: .init(elementType: type(of: element), key: nil, count: 1),
                    element: element
                )
            }
        }
    }
}


final class ElementState {
    
    let identifier : ElementIdentifier
    var element : Element
                    
    init(identifier : ElementIdentifier, element : Element) {
        self.identifier = identifier
        self.element = element
    }
    
    func update(with newElement : Element, identifier : ElementIdentifier) {
        
        precondition(self.identifier == identifier)
        
        let isEquivalent = self.element.checkIsEquivalentTo(other: newElement)
        
        if isEquivalent == false {
            self.measurements = [:]
        }
        
        self.element = newElement
    }
    
    func setup() {
        
    }
    
    func teardown() {
        // TODO
        
        self.removeAll()
    }
    
    private var measurements: [SizeConstraint: CGSize] = [:]

    func measure(in constraint : SizeConstraint, using measurer : () -> CGSize) -> CGSize {
        
        if let existing = self.measurements[constraint] { return existing }
        
        let new = measurer()
        
        self.measurements[constraint] = new
        
        return new
    }
    
    private var children : [ElementIdentifier:ElementState] = [:]
    
    func subState(for child : Element, with identifier : ElementIdentifier) -> ElementState {
        if let existing = self.children[identifier] {
            return existing
        } else {
            let new = ElementState(identifier: identifier, element: child)
            
            self.children[identifier] = new
            
            return new
        }
    }
    
    func removeOldChildren(keeping liveIdentifiers : Set<ElementIdentifier>) {
        
        let removed = Set(self.children.keys).subtracting(liveIdentifiers)
        
        removed.forEach {
            let state = self.children[$0]
            
            // Ensures that all of the child states which are going away are removed as well.
            state?.children.removeAll()
            
            state?.teardown()
            
            self.children.removeValue(forKey: $0)
        }
    }
    
    func removeAll() {
        self.removeOldChildren(keeping: [])
    }
}


fileprivate extension Element {
    
    func checkIsEquivalentTo(other : Element) -> Bool {
        
        guard let self = self as? AnyEquatableElement else { return false }
        guard let other = other as? AnyEquatableElement else { return false }
        
        return self.anyIsEquivalentTo(other: other)
    }
}


//
// MARK: CustomDebugStringConvertible
//


extension ElementState : CustomDebugStringConvertible {
    
    public var debugDescription: String {
        
        var debugRepresentations = [ElementState.DebugRepresentation]()
        
        self.children.values.forEach {
            $0.appendDebugDescriptions(to: &debugRepresentations, at: 0)
        }
        
        let strings : [String] = debugRepresentations.map { child in
            Array(repeating: "  ", count: child.depth).joined() + "\(type(of:child.element)) #\(child.identifier.count)"
        }
        
        return strings.joined(separator: "\n")
    }
}


extension ElementState {
    
    func appendDebugDescriptions(to : inout [DebugRepresentation], at depth: Int) {
        to.append(DebugRepresentation(depth: depth, identifier: self.identifier, element:self.element))
        
        self.children.values.forEach { child in
            child.appendDebugDescriptions(to: &to, at: depth + 1)
        }
    }
    
    struct DebugRepresentation {
        var depth : Int
        var identifier : ElementIdentifier
        var element : Element
    }
}
