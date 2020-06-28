//
//  ElementTreeState.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 6/23/20.
//

import Foundation


final class ElementState
{
    private(set) var element : Element
    private(set) var key : AnyHashable?
    
    private(set) weak var parent : ElementState?
    
    private(set) var children : [ElementState]
    
    init(element : Element, key : AnyHashable?, parent : ElementState?)
    {
        self.element = element
        self.key = key
        self.parent = parent
        
        self.children = []
        
        self.children = self.element.content.children(in: .empty).map { child in
            .init(element: child.element, key: child.key, parent: self)
        }
    }
    
    func update(with element : Element)
    {
        let newChildren = element.content.children(in: .empty)
        
        if self.children.isEmpty && newChildren.isEmpty {
            // Fast path. No changes at all, both sides of the change are empty.
            
        } else if self.children.count == 1 && newChildren.count == 1 {
            // Fast path: Same count before and after, we can just check types without diffing.
            
            let newChild = newChildren[0]
            
            let isSame = DiffIdentifier(self.element, key: self.key) == DiffIdentifier(newChild.element, key: newChild.key)
            
            if isSame {
                self.children[0].update(with: newChild.element)
            } else {
                self.children = [ElementState(element: newChild.element, key: newChild.key, parent: self)]
            }
            
        } else if self.children.isEmpty && newChildren.isEmpty == false {
            // Fast path: All children were added. Add them without diffing.
            
            self.children = newChildren.map {
                ElementState(element: $0.element, key: $0.key, parent: self)
            }

        } else if self.children.isEmpty == false && newChildren.isEmpty {
            // Fast path: All children were removed. Remove them without diffing.
            
            self.children = []
        } else {
            // Slightly slower paths, where we need to compare contained elements.
            
            let oldIDs = DiffIdentifier.identifiers(with: self.children)
            let newIDs = DiffIdentifier.identifiers(with: newChildren)
            
            if oldIDs == newIDs {
                // Fast path, no diffing needed. Just update in place.
                
                for (index, child) in self.children.enumerated() {
                    child.update(with: newChildren[index].element)
                }
            } else {
                // Slow path: Some other type of change happened, diff the collections.
                
                var old = [DiffIdentifier:ElementState]()
                
                for (index, child) in self.children.enumerated() {
                    old[oldIDs[index]] = child
                }
                
                var new = [ElementState]()
                
                for (index, child) in newChildren.enumerated() {
                    
                }
            }
        }
    }
}


extension ElementState
{
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
        
        static func identifiers(with state : [ElementState]) -> [DiffIdentifier]
        {
            var factory = Factory()
            factory.reserveCapacity(state.count)
            
            return state.lazy.map {
                factory.makeIdentifier(for: type(of: $0.element), key: $0.key)
            }
        }
        
        static func identifiers(with children : [AnyElementContentChild]) -> [DiffIdentifier]
        {
            var factory = Factory()
            factory.reserveCapacity(children.count)
            
            return children.lazy.map {
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
    
    struct Diff<Diffed:Hashable> {
        
        let inserted : [Inserted]
        let removed : [Removed]
        let moved : [Moved]
        let noChange : [NoChange]
        
        init(old : [Diffed], new : [Diffed]) {
                        
            var added = Set(new)
            var removed = Set(old)
            
            precondition(added.count == new.count, "Duplicate identifiers")
            precondition(removed.count == old.count, "Duplicate identifiers")

            added.subtract(old)
            removed.subtract(new)
            
            let oldIndexes : [Diffed:Int] = old.toDictionary { ($1, $0) }
            let newIndexes : [Diffed:Int] = new.toDictionary { ($1, $0) }
            
            self.inserted = added.map {
                .init(index: newIndexes[$0]!, newValue: $0)
            }.sorted {
                $0.index < $1.index
            }
            
            self.removed = removed.map {
                .init(index: oldIndexes[$0]!, oldValue: $0)
            }.sorted {
                $0.index > $1.index
            }
            
            if old.isEmpty || new.isEmpty {
                self.moved = []
                self.noChange = []
            } else {
                let overlappingOld = old.compactMap {
                    added.contains($0) == false && removed.contains($0) == false ? $0 : nil
                }
                
                let overlappingNew = new.compactMap {
                    added.contains($0) == false && removed.contains($0) == false ? $0 : nil
                }
                
                precondition(overlappingOld.count == overlappingNew.count, "Overlapping counts must match.")
                
                if overlappingOld == overlappingNew {
                    self.moved = []
                    
                    self.noChange = overlappingNew.map {
                        NoChange(oldIndex: oldIndexes[$0]!, newIndex: newIndexes[$0]!, value: $0)
                    }
                } else {
                    var moved = [Moved]()
                    var noChange = [NoChange]()
                    
                    var currentOld = OrderedSet(overlappingNew)
                    let currentNew = OrderedSet(overlappingNew)
                    
                    let range = (0 ..< overlappingNew.count)
                    
                    for index in range {
                        let value = currentOld[index]
                        let newIndex = currentNew.index(of: value)
                        
                        if index != newIndex {
                            currentOld.move(from: index, to: newIndex)
                            moved.append(Moved(oldIndex: oldIndexes[value]!, newIndex: newIndexes[value]!, value: value))
                        } else {
                            noChange.append(NoChange(oldIndex: oldIndexes[value]!, newIndex: newIndexes[value]!, value: value))
                        }
                    }
                    
                    self.moved = moved
                    self.noChange = noChange
                }
            }
        }
        
        mutating func transform<Element>(
            _ array : [Element],
            inserted : (Inserted) -> Element,
            removed : (Element, Removed) -> (),
            moved : (inout Element, Moved) -> (),
            notChanged : (inout Element, NoChange) -> ()
        ) -> [Element]
        {
            var new = array
            
            self.removed.forEach {
                let value = new[$0.index]
                new.remove(at: $0.index)
                
                removed(value, $0)
            }
            
            self.moved.sorted { $0.oldIndex > $1.oldIndex }.forEach {
                var value = 
            }
            
            self.inserted.forEach {
                let value = inserted($0)
                new.insert(value, at: $0.index)
            }
            
            
            
            return new
        }
        
        struct OrderedSet {
            private var values : [Diffed]
            private var indexes : [Diffed:Int]
            
            init(_ values : [Diffed])
            {
                self.values = values
                
                self.indexes = self.values.toDictionary {
                    ($1, $0)
                }
            }
            
            subscript(_ index : Int) -> Diffed {
                self.values[index]
            }
            
            mutating func move(from oldIndex : Int, to newIndex : Int)
            {
                guard oldIndex != newIndex else {
                    return
                }
                
                let value = self.values.remove(at: oldIndex)
                
                self.values.insert(value, at: newIndex)
                
                self.indexes = self.values.toDictionary {
                    ($1, $0)
                }
            }
            
            func index(of element : Diffed) -> Int {
                self.indexes[element]!
            }
        }
        
        struct Inserted {
            let index : Int
            let newValue : Diffed
        }
        
        struct Removed {
            let index : Int
            let oldValue : Diffed
        }
        
        struct Moved {
            let oldIndex : Int
            let newIndex : Int
            
            let value : Diffed
        }
        
        struct NoChange {
            let oldIndex : Int
            let newIndex : Int
            
            let value : Diffed
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
