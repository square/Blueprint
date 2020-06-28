//
//  ElementTreeState.swift
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


final class LiveElementState
{
    // MARK: Element Data
    
    private let key : AnyHashable?
    
    private(set) var element : Element
    
    // MARK: Parent / Child Tree
    
    private(set) weak var parent : LiveElementState?
    
    private(set) var children : [LiveElementState]
    
    // MARK: Initialization
    
    init(element : Element, key : AnyHashable?, parent : LiveElementState?)
    {
        self.element = element
        self.key = key
        self.parent = parent
        
        self.children = []
        
        self.children = self.element.content.children(in: .empty).map { child in
            .init(element: child.element, key: child.key, parent: self)
        }
    }
    // MARK: Updating
    
    private func validate(update updated : Element)
    {
        precondition(type(of: self.element) == type(of: updated))
    }
    
    func update(with element : Element)
    {
        self.validate(update: element)
        
        let newChildren = element.content.children(in: .empty)
        
        if self.children.isEmpty && newChildren.isEmpty {
            // Fast path. No changes at all – we don't have any children.
        } else if self.children.count == 1 && newChildren.count == 1 {
            // Fast path: Same count before and after, we can just check types without diffing.
            
            let newChild = newChildren[0]
            
            let isSame = DiffIdentifier(self.element, key: self.key) == DiffIdentifier(newChild.element, key: newChild.key)
            
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
        
        self.element = element
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
    final class Lazy<Value> {
        
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


extension LiveElementState.Lazy : Equatable where Value : Equatable {
    static func == (lhs: LiveElementState.Lazy<Value>, rhs: LiveElementState.Lazy<Value>) -> Bool {
        lhs.value == rhs.value
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
