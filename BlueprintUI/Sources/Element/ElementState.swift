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
                identifier: .init(element: element, key: nil, count: 1),
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


final class ElementState {
    
    let identifier : ElementIdentifier
    let depth : Int
    let signpostRef : AnyObject
    let name : String
    
    private(set) var element : Element
    
    let isElementComparable : Bool
    
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
        self.isElementComparable = self.element is AnyComparableElement
        
        self.depth = depth
        self.signpostRef = signpostRef
        self.name = name
        
        self.wasVisited = true
        self.hasUpdatedInCurrentCycle = true
    }
    
    fileprivate func update(
        with newElement : Element,
        in newEnvironment : Environment,
        identifier : ElementIdentifier
    ) {
        precondition(self.identifier == identifier)
        
        let isEquivalent : Bool = {
            do {
                return try Self.elementsEquivalent(self.element, newElement)
            } catch {
                guard error is ComparableElementNotEquivalent else {
                    fatalError("Can only throw `ComparableElementNotEquivalent` from `isEquivalent`.")
                }
                
                return false
            }
        }()
        
        if isEquivalent == false {
            // TODO: Log / enable-able debugging in here for determining what is being invalidated. Use signposts too?
            self.clearAllCachedData()
        } else {
            self.measurements.removeAll { _, measurement in
                newEnvironment.valuesEqual(to: measurement.dependencies) == false
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
        var dependencies : Environment.Subset?
    }

    func measure(
        in constraint : SizeConstraint,
        with context : LayoutContext,
        using measurer : (LayoutContext) -> CGSize
    ) -> CGSize
    {
        if let existing = self.measurements[constraint] {
            return existing.size
        }
        
        let (size, dependencies) = self.trackEnvironmentReads(with: context, in: measurer)
        
        self.measurements[constraint] = .init(
            size: size,
            dependencies: dependencies
        )
                
        return size
    }
    
    private func trackEnvironmentReads<Output>(
        with context : LayoutContext,
        in toTrack : (LayoutContext) -> Output
    ) -> (Output, Environment.Subset?)
    {
        var context = context
        var observedKeys = Set<Environment.StorageKey>()
        
        context.environment.onDidRead = { key in
            observedKeys.insert(key)
        }
                
        let output = toTrack(context)
        
        return (output, context.environment.subset(with: observedKeys))
    }
    
    private var children : [ElementIdentifier:ElementState] = [:]
    
    func childState(
        for child : Element,
        in environment : Environment,
        with identifier : ElementIdentifier
    ) -> ElementState
    {
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
    
    func viewSizeChanged(from : CGSize, to : CGSize) {
        
        if from == to { return }
        
        if let element = self.element as? AnyComparableElement {
            if element.willSizeChangeAffectLayout(from: from, to: to) {
                self.clearAllCachedData()
            }
        } else {
            self.clearAllCachedData()
        }
        
        self.children.forEach { _, value in
            value.viewSizeChanged(from: from, to: to)
        }
    }
    
    func prepareForLayout() {
        self.recursiveForEach {
            $0.wasVisited = false
            $0.hasUpdatedInCurrentCycle = false
        }
    }
    
    func finishedLayout() {
        self.recursiveRemoveOldChildren()
        self.recursiveClearNonComparableElementCaches()
    }
    
    private func clearAllCachedData() {
        self.measurements.removeAll()
    }
    
    func recursiveForEach(_ perform : (ElementState) -> ()) {
        perform(self)
        
        self.children.forEach { _, child in
            child.recursiveForEach(perform)
        }
    }
    
    private func recursiveRemoveOldChildren() {
        
        for (key, state) in self.children {
            
            if state.wasVisited { continue }
            
            state.teardown()
            
            self.children.removeValue(forKey: key)
        }
        
        self.children.forEach { _, state in
            state.recursiveRemoveOldChildren()
        }
    }
    
    func recursiveClearAllCachedData() {
        self.recursiveForEach {
            $0.clearAllCachedData()
        }
    }
    
    private func recursiveClearNonComparableElementCaches() {
        self.recursiveForEach {
            if $0.isElementComparable == false {
                $0.clearAllCachedData()
            }
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


extension ElementState {
    
    static func elementsEquivalent(_ lhs : Element?, _ rhs : Element?) throws -> Bool {
        
        if lhs == nil && rhs == nil { return true }
        
        guard let lhs = lhs as? AnyComparableElement else { return false }
        guard let rhs = rhs as? AnyComparableElement else { return false }
        
        return try lhs.anyIsEquivalent(to: rhs)
    }
}


fileprivate extension Dictionary {
    
    mutating func removeAll(where shouldRemove : (Key, Value) -> Bool) {
        
        for (key, value) in self {
            if shouldRemove(key, value) {
                self.removeValue(forKey: key)
            }
        }
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
            measurements: self.measurements
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
        
        var debugDescription : String {
            "\(type(of:self.element)) #\(self.identifier.count): \(self.measurements.count) Measurements"
        }
    }
}

