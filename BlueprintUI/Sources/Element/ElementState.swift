//
//  ElementState.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 6/24/21.
//

import Foundation


final class RootElementState {
    
    private(set) var root : ElementState?
    
    private let signpostRef : SignpostToken = .init()
    let name : String
    
    init(name : String) {
        self.name = name
    }
    
    func update(with element : Element?) {
        
        if self.root == nil, let element = element {
            self.root = ElementState(
                identifier: .init(elementType: type(of: element), key: nil, count: 1),
                element: element,
                signpostRef: self.signpostRef,
                name: self.name
            )
        } else if let root = self.root, element == nil {
            root.teardown()
            self.root = nil
        } else if let root = self.root, let element = element {
            if type(of: root.element) == type(of: element) {
                root.update(with: element, identifier: root.identifier)
            } else {
                root.teardown()
                
                self.root = ElementState(
                    identifier: .init(elementType: type(of: element), key: nil, count: 1),
                    element: element,
                    signpostRef: self.signpostRef,
                    name: self.name
                )
            }
        }
    }
}


final class ElementState {
    
    let identifier : ElementIdentifier
    
    var element : Element
    
    let signpostRef : AnyObject
    let name : String
    
    private(set) var wasVisited : Bool = false
    private(set) var hasUpdatedInCurrentCycle : Bool = false
                    
    init(
        identifier : ElementIdentifier,
        element : Element,
        signpostRef : AnyObject,
        name : String
    ) {
        print("Making new for \(type(of:element))")
        
        self.identifier = identifier
        self.element = element
        self.signpostRef = signpostRef
        self.name = name
    }
    
    func update(with newElement : Element, identifier : ElementIdentifier) {
        
        precondition(self.identifier == identifier)
        
        let isEquivalent = self.element.checkIsEquivalentTo(other: newElement)
        
        if isEquivalent == false {
            
//            if String(describing: type(of:self.element)) == "Label" {
//                print("")
//            }
            
            self.measurements = [:]
        }
        
        self.element = newElement
    }
    
    func setup() {
        
    }
    
    func teardown() {
        
    }
    
    private var measurements: [SizeConstraint: CGSize] = [:]

    func measure(in constraint : SizeConstraint, using measurer : () -> CGSize) -> CGSize {
        
        if let existing = self.measurements[constraint] {
            return existing
        }
        
        print("Measuring new for \(type(of:self.element))")
        
        let new = measurer()
        
        self.measurements[constraint] = new
                
        return new
    }
    
    private var children : [ElementIdentifier:ElementState] = [:]
    
    func subState(for child : Element, with identifier : ElementIdentifier) -> ElementState {
        if let existing = self.children[identifier] {
            existing.wasVisited = true
            
            // TODO: Is this right? Or should we restrict to measurement only?
            if self.hasUpdatedInCurrentCycle == false {
                existing.update(with: child, identifier: identifier)
                self.hasUpdatedInCurrentCycle = true
            }
            
            return existing
        } else {
            let new = ElementState(
                identifier: identifier,
                element: child,
                signpostRef: self.signpostRef,
                name: self.name
            )
            
            new.wasVisited = true
            
            self.children[identifier] = new
            
            return new
        }
    }
    
    func prepareForLayout() {
        
        self.wasVisited = false
        self.hasUpdatedInCurrentCycle = false
        
        self.children.forEach { _, state in
            state.prepareForLayout()
        }
    }
    
    func finishedLayout() {
        
        self.removeOldChildren()
    }
    
    private func removeOldChildren() {
        let old : [ElementIdentifier] = self.children.compactMap { id, state in
            state.wasVisited ? nil : id
        }
        
        old.forEach {
            guard let state = self.children[$0] else { fatalError() }
            
            state.teardown()
            
            self.children.removeValue(forKey: $0)
        }
        
        self.children.forEach { _, state in
            state.removeOldChildren()
        }
    }
}

/// A token reference type that can be used to group associated signpost logs using `OSSignpostID`.
private final class SignpostToken {}


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
            Array(repeating: "  ", count: child.depth).joined() + child.debugDescription
        }
        
        return strings.joined(separator: "\n")
    }
}


extension ElementState {
    
    func appendDebugDescriptions(to : inout [DebugRepresentation], at depth: Int) {
        
        let info = DebugRepresentation(
            objectIdentifier: ObjectIdentifier(self),
            depth: depth,
            identifier: self.identifier,
            element:self.element,
            measurements: self.measurements
        )
        
        to.append(info)
        
        self.children.values.forEach { child in
            child.appendDebugDescriptions(to: &to, at: depth + 1)
        }
    }
    
    struct DebugRepresentation : CustomDebugStringConvertible{
        var objectIdentifier : ObjectIdentifier
        var depth : Int
        var identifier : ElementIdentifier
        var element : Element
        var measurements : [SizeConstraint:CGSize]
        
        var debugDescription : String {
            "\(type(of:self.element)) #\(self.identifier.count): \(self.measurements.count) Measurements"
        }
    }
}
