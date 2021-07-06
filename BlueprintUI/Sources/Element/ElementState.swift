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
    
    func update(with element : Element?, in environment : Environment) {
        
        func makeRoot(with element : Element) {
            self.root = ElementState(
                identifier: .init(elementType: type(of: element), key: nil, count: 1),
                element: element,
                depth: 0,
                signpostRef: self.signpostRef,
                name: self.name
            )
        }
        
        if self.root == nil, let element = element {
            makeRoot(with: element)
        } else if let root = self.root, element == nil {
            root.teardown()
            self.root = nil
        } else if let root = self.root, let element = element {
            if type(of: root.element) == type(of: element) {
                root.update(with: element, in: environment, identifier: root.identifier)
            } else {
                root.teardown()
                makeRoot(with: element)
            }
        }
    }
}


// TODO: Using Allocations instrument; during initial setup, NSFastEnumerator is using >20mb of something. Probably need an autoreleasepool somewhere...

final class ElementState {
    
    let identifier : ElementIdentifier
    let depth : Int
    let signpostRef : AnyObject
    let name : String
    
    private(set) var element : Element
    
    var elementIsEquatable : Bool {
        self.element is AnyEquatableElement
    }
    
    private(set) var wasVisited : Bool = false
    private(set) var hasUpdatedInCurrentCycle : Bool = false
                    
    init(
        identifier : ElementIdentifier,
        element : Element,
        depth : Int,
        signpostRef : AnyObject,
        name : String
    ) {
        self.identifier = identifier
        self.element = element
        self.depth = depth
        self.signpostRef = signpostRef
        self.name = name
        
        self.wasVisited = true
        self.hasUpdatedInCurrentCycle = true
    }
    
    func update(
        with newElement : Element,
        in newEnvironment : Environment,
        identifier : ElementIdentifier
    ) {
        precondition(self.identifier == identifier)
        
        if Self.elementsEquivalent(self.element, newElement) == false {
            self.measurements = [:]
            self.layouts = [:]
        } else {
            for (_, result) in self.measurements {
                guard let dependency = result.environmentDependency else { continue }
                if dependency.trackedKeysEqual(to: newEnvironment) == false {
                    self.measurements.removeAll()
                    break
                }
            }
            
            for (_, result) in self.layouts {
                guard let dependency = result.environmentDependency else { continue }
                if dependency.trackedKeysEqual(to: newEnvironment) == false {
                    self.layouts.removeAll()
                    break
                }
            }
        }
        
        self.element = newElement
    }
    
    func setup() {
        
    }
    
    func teardown() {
        
    }
    
    private var measurements: [SizeConstraint:CachedMeasurement] = [:]
    
    private struct CachedMeasurement {
        var size : CGSize
        var environmentDependency : EnvironmentDependency?
    }

    // TODO: I think because we also cache layout; we can remove every one here but the one(s) used by cached layouts?
    // TODO: cont'd: this will help save a lot of in-memory space for caches, since deep elements can be measured 10 times (or more) during a layout.
    func measure(
        in constraint : SizeConstraint,
        with environment : Environment,
        using measurer : (Environment) -> CGSize
    ) -> CGSize
    {
        if let existing = self.measurements[constraint] {
            return existing.size
        }
        
        var environment = environment
        var readEnvironmentKeys = Set<Environment.StorageKey>()

        environment.onDidRead = { key in
            readEnvironmentKeys.insert(key)
        }
                
        let size = measurer(environment)
        
        self.measurements[constraint] = .init(
            size: size,
            environmentDependency: .init(from: environment, keys: readEnvironmentKeys)
        )
                
        return size
    }
    
    typealias LayoutResult = [(identifier: ElementIdentifier, node: LayoutResultNode)]
    
    // TODO: Cache all of them, or just the most few recent / most recent?
    private var layouts : [CGSize:CachedLayoutResult] = [:]
    
    private struct CachedLayoutResult {
        var result : LayoutResult
        var environmentDependency : EnvironmentDependency?
    }
    
    // TODO: Does this get multiplicatively expensive with deep trees? Does it matter?
    func layout(
        in size : CGSize,
        with environment : Environment,
        using layout : (Environment) -> LayoutResult
    ) -> LayoutResult {
        
        if let existing = self.layouts[size] {
            return existing.result
        }
        
        var environment = environment
        var readEnvironmentKeys = Set<Environment.StorageKey>()
        
        environment.onDidRead = { key in
            readEnvironmentKeys.insert(key)
        }
                
        let result = layout(environment)
        
        self.layouts[size] = .init(
            result: result,
            environmentDependency: .init(from: environment, keys: readEnvironmentKeys)
        )
                
        return result
    }
    
    private var children : [ElementIdentifier:ElementState] = [:]
    
    func subState(for child : Element, in environment : Environment, with identifier : ElementIdentifier) -> ElementState {
        if let existing = self.children[identifier] {
            existing.wasVisited = true
            
            if self.hasUpdatedInCurrentCycle == false {
                existing.update(with: child, in: environment, identifier: identifier)
                self.hasUpdatedInCurrentCycle = true
            }
            
            return existing
        } else {
            let new = ElementState(
                identifier: identifier,
                element: child,
                depth: self.depth + 1,
                signpostRef: self.signpostRef,
                name: self.name
            )
            
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
        self.clearNonPersistentCaches()
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
    
    private func clearNonPersistentCaches() {
        
        if self.elementIsEquatable == false {
            self.measurements.removeAll()
            self.layouts.removeAll()
        }
        
        self.children.forEach { _, state in
            state.clearNonPersistentCaches()
        }
    }
}


extension ElementState {
    
    fileprivate struct EnvironmentDependency {
        let dependencies : Environment.Subset
        
        init?(from environment : Environment, keys : Set<Environment.StorageKey>) {
            if keys.isEmpty {
                return nil
            } else {
                self.dependencies = environment.subset(keeping: keys)
            }
        }
        
        func trackedKeysEqual(to environment : Environment) -> Bool {
            environment.isEqual(to: self.dependencies)
        }
    }
}


extension CGSize : Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.width)
        hasher.combine(self.height)
    }
}


/// A token reference type that can be used to group associated signpost logs using `OSSignpostID`.
private final class SignpostToken {}


fileprivate extension ElementState {
    
    static func elementsEquivalent(_ lhs : Element, _ rhs : Element) -> Bool {
        
        guard let lhs = lhs as? AnyEquatableElement else { return false }
        guard let rhs = rhs as? AnyEquatableElement else { return false }
        
        return lhs.anyIsEquivalentTo(other: rhs)
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
    
    private func appendDebugDescriptions(to : inout [DebugRepresentation], at depth: Int) {
        
        let info = DebugRepresentation(
            objectIdentifier: ObjectIdentifier(self),
            depth: depth,
            identifier: self.identifier,
            element:self.element,
            measurements: self.measurements,
            layouts: self.layouts
        )
        
        to.append(info)
        
        self.children.values.forEach { child in
            child.appendDebugDescriptions(to: &to, at: depth + 1)
        }
    }
    
    private struct DebugRepresentation : CustomDebugStringConvertible{
        var objectIdentifier : ObjectIdentifier
        var depth : Int
        var identifier : ElementIdentifier
        var element : Element
        var measurements : [SizeConstraint:CachedMeasurement]
        var layouts : [CGSize:CachedLayoutResult]
        
        var debugDescription : String {
            "\(type(of:self.element)) #\(self.identifier.count): \(self.measurements.count) Measurements, \(self.layouts.count) Layouts"
        }
    }
}
