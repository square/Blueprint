//
//  LiveElementState.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 6/23/20.
//

import Foundation


struct RootElement : ProxyElement {
    var root : Element
    
    var elementRepresentation: Element {
        self.root
    }
}


final class LiveElementState : Measurable // TODO eventually conform in a smaller type
{
    // MARK: Element Data
    
    private let key : AnyHashable?
    
    private(set) var element : Element
    private(set) var elementContent : ElementContent
    private(set) var viewDescription : ViewDescription?
    
    // MARK: Parent / Child Tree
    
    private(set) weak var parent : LiveElementState?
    
    private(set) var children : [LiveElementState]
    
    // MARK: State Management
    
    let elementStateController : ElementStateController?
    
    // MARK: Initialization
    
    init(element : Element, key : AnyHashable?, parent : LiveElementState?)
    {
        StatefulElementPropertyValidator.validate(typeOf: element)
        
        self.key = key
        
        self.elementStateController = ElementStateController(with: element)
        
        self.element = self.elementStateController?.setting(on: element) ?? element
        self.elementContent = self.element.content
        
        self.parent = parent
        
        self.children = []
        
        self.elementStateController?.stateDidChange = { [weak self] in
            self?.elementStateControllerStateDidChange()
        }
        
        self.update(with: element)
    }
    
    // MARK: Measurement & Layout
    
    private var needsUpdate : Bool = true
    
    func setNeedsUpdate() {
        self.needsUpdate = true
    }
    
    var cachedMeasurements : [SizeConstraint:CGSize] = [:]
    
    func measure(in constraint: SizeConstraint) -> CGSize
    {
        fatalError()
    }
    
    func measure(in constraint : SizeConstraint, environment : Environment) -> CGSize
    {
        if let existing = self.cachedMeasurements[constraint] {
            return existing
        }
        
        // TODO...
        let measurement : CGSize = .zero
        
        self.cachedMeasurements[constraint] = measurement
        
        return measurement
    }
    
    func layout(in size : CGSize)
    {
        fatalError()
    }
    
    // MARK: State
    
    func elementStateControllerStateDidChange()
    {
        // TODO: How to do "backpressure" up the stack?
        // Measure ourselves in an infinite bounds and if that changes from last time, push up recursively?
        
        self.setNeedsUpdate()
    }
    
    // MARK: Updating
    
    private func validate(update updated : Element)
    {
        precondition(type(of: self.element) == type(of: updated))
    }
    
    func update(with intermediateNewElement : Element)
    {
        self.validate(update: intermediateNewElement)
        
        let oldElement = self.element
        let oldElementContent = self.elementContent
        let oldViewDescription = self.viewDescription
        
        self.element = self.elementStateController?.setting(on: intermediateNewElement) ?? intermediateNewElement
        
        self.elementContent = self.element.content
        self.viewDescription = self.element.backingViewDescription(bounds: .zero, subtreeExtent: nil)
        
        let newChildren = self.elementContent.children(in: .empty)
        
        if self.children.isEmpty && newChildren.isEmpty {
            // Fast path. No changes at all – we don't have any children.
        } else if self.children.count == 1 && newChildren.count == 1 {
            // Fast path: Same count before and after, we can just check types without diffing.
            
            let newChild = newChildren[0]
            
            let isSame = DiffIdentifier(oldElement, key: self.key) == DiffIdentifier(self.element, key: newChild.key)
            
            if isSame {
                self.children[0].update(with: newChild.element)
            } else {
                self.didRemove(self.children[0])
                
                let new = LiveElementState(element: newChild.element, key: newChild.key, parent: self)
                self.children = [new]
                self.didInsert(new)
            }
            
        } else if self.children.isEmpty && newChildren.isEmpty == false {
            // Fast path: All children were added. Add them without diffing.
            
            self.children = newChildren.map {
                LiveElementState(element: $0.element, key: $0.key, parent: self)
            }
            
            self.children.forEach {
                self.didInsert($0)
            }

        } else if self.children.isEmpty == false && newChildren.isEmpty {
            // Fast path: All children were removed. Remove them without diffing.
            
            self.children.forEach {
                self.didRemove($0)
            }
            
            self.children = []
        } else {
            // Slightly slower paths, where we need to compare contained elements.
            
            let oldIDs = Lazy { DiffIdentifier.identifiers(with: self.children) }
            let newIDs = Lazy { DiffIdentifier.identifiers(with: newChildren) }
            
            let countsMatch = self.children.count == newChildren.count
            
            if countsMatch && oldIDs == newIDs {
                // Fast path, no diffing needed. Just update in place.
                
                for (index, child) in self.children.enumerated() {
                    child.update(with: newChildren[index].element)
                }
            } else {
                // Slow path: Some other type of change happened, diff the collections.
                
                let oldIDs = OrderedSet(oldIDs.value)
                let newIDs = OrderedSet(newIDs.value)
                
                var old = [DiffIdentifier:LiveElementState]()
                
                for (index, child) in self.children.enumerated() {
                    let ID = oldIDs[index]
                    old[ID] = child
                }
                
                var new = [LiveElementState]()
                
                for (index, child) in newChildren.enumerated() {
                    let ID = newIDs[index]
                    
                    
                    if let existing = old.removeValue(forKey: ID) {
                        new.append(existing)
                        
                        existing.update(with: child.element)
                        
                        let indexChanged = oldIDs[ID] != newIDs[ID]
                        
                        if indexChanged {
                            // TODO Move the view to the right place in the hierarchy.
                        }
                    } else {
                        let newState = LiveElementState(element: child.element, key: child.key, parent: self)
                        new.append(newState)
                        
                        self.didInsert(newState)
                    }
                }
                
                for (_, removed) in old {
                    self.didRemove(removed)
                }
                
                self.children = new
            }
        }
    }
    
    func didInsert(_ state : LiveElementState) {
        // TODO...
    }
    
    func didRemove(_ state : LiveElementState) {
        // TODO...
    }
}


extension LiveElementState
{
    final class Lazy<Value:Equatable> : Equatable {
        
        var value : Value {
            get {
                if let value = self.storage {
                    return value
                } else {
                    let value = self.provider()
                    self.storage = value
                    return value
                }
            }
        }
        
        private var provider : () -> Value
        private var storage : Value?
        
        init(_ provider : @escaping () -> Value) {
            self.provider = provider
        }
        
        static func == (lhs: Lazy, rhs: Lazy) -> Bool {
            lhs.value == rhs.value
        }
    }
    
    struct OrderedSet<Element:Hashable> {
    
        let values : [Element]
        let indexes : [Element:Int]
        
        init(_ values : [Element]) {
            self.values = values
            self.indexes = self.values.toDictionary { ($1, $0) }
        }
        
        subscript(_ index : Int) -> Element {
            self.values[index]
        }
        
        subscript(_ element : Element) -> Int {
            self.indexes[element]!
        }
    }
    
    struct DiffIdentifier : Hashable {
        
        private let typeIdentifier : ObjectIdentifier
        private let key : AnyHashable?
        private let count : Int
        
        private let hashCode : Int
        
        init(_ element : Element, key : AnyHashable?)
        {
            self.init(ObjectIdentifier(type(of: element)), key: key, count: 0)
        }
        
        init(_ typeIdentifier : ObjectIdentifier, key : AnyHashable?, count : Int)
        {
            self.typeIdentifier = typeIdentifier
            self.key = key
            self.count = count
            
            var hasher = Hasher()
            hasher.combine(self.typeIdentifier)
            hasher.combine(self.key)
            hasher.combine(self.count)
            self.hashCode = hasher.finalize()
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(self.hashCode)
        }
        
        static func identifiers(with state : [LiveElementState]) -> [DiffIdentifier]
        {
            var factory = Factory()
            factory.reserveCapacity(state.count)
            
            return state.map {
                factory.makeIdentifier(for: type(of: $0.element), key: $0.key)
            }
        }
        
        static func identifiers(with children : [AnyElementContentChild]) -> [DiffIdentifier]
        {
            var factory = Factory()
            factory.reserveCapacity(children.count)
            
            return children.map {
                factory.makeIdentifier(for: type(of: $0.element), key: $0.key)
            }
        }
        
        private struct Factory {
            
            private var counts : [Key:Int] = [:]
            
            mutating func reserveCapacity(_ count: Int) {
                self.counts.reserveCapacity(count)
            }
            
            mutating func makeIdentifier(for elementType : Element.Type, key : AnyHashable?) -> DiffIdentifier {
                let typeIdentifier = ObjectIdentifier(elementType)
                let key = Key(typeIdentifier: typeIdentifier, key: key)
                
                let count = self.counts[key, default: 1]
                
                let identifier = DiffIdentifier(typeIdentifier, key: key, count: count)
                
                self.counts[key] = count + 1
                
                return identifier
            }
            
            private struct Key : Hashable {
            
                private let typeIdentifier : ObjectIdentifier
                private let key : AnyHashable?
                
                private let hashCode : Int
                
                init(typeIdentifier: ObjectIdentifier, key: AnyHashable?) {
                    self.typeIdentifier = typeIdentifier
                    self.key = key
                    
                    var hasher = Hasher()
                    hasher.combine(self.typeIdentifier)
                    hasher.combine(self.key)
                    self.hashCode = hasher.finalize()
                }
                
                func hash(into hasher: inout Hasher) {
                    hasher.combine(self.hashCode)
                }
            }
        }
    }
}


fileprivate extension Array {
        
    func toDictionary<Key:Hashable, Value>(_ pairProvider : (Int, Element) -> (Key, Value)) -> [Key:Value] {
        
        var dictionary : [Key:Value] = Dictionary(minimumCapacity: self.count)
        
        for (index, element) in self.enumerated() {
            let (key, value) = pairProvider(index, element)
            
            precondition(dictionary[key] == nil)
            
            dictionary[key] = value
        }
        
        return dictionary
    }
}
