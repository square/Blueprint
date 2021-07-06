
/**
 An identifier used to uniquely identify elements during diff
 and update operations.
 
 The identifier has three parts:
 1) The type of the underlying element, represented by `elementType`.
 
 2) The key. This is an optional value provided by developers using Blueprint to further
 disambiguate identical elements within a hierarchy. This is optional, and is rarely provided.
 When it is provided, `elementType` + ` key` is used to disambiguate elements.
 
 3) The occurrence count of that type of `elementType` + `key` in the hierarchy.
 For example, if I have a hierarchy of [A, B, B] the counts will be [1, 1, 2] respectively.

 A fully constructed `ElementIdentifier` would look like this:
 
 ```
 ElementIdentifier(elementType: MyElement.self, key: nil, count: 2)
 ```
 
 Which means that this identifier represents an element of type `MyElement`, which is
 the second `MyElement` element in the hierarchy.
 
 Elements are identified and counted by their `elementType` and `key` to further assist in diffing during update operations.
 
 For example, if we started with:
 ```
 ElementA -> ElementIdentifier(ElementA.self, [optional key], 1)
 ElementB -> ElementIdentifier(ElementB.self, [optional key], 1)
 ElementB -> ElementIdentifier(ElementB.self, [optional key], 2)
 ElementC -> ElementIdentifier(ElementC.self, [optional key], 1)
 ```
 
 And then removed A and the first B:
 
 ```
 ElementB -> ElementIdentifier(ElementB.self, [optional key], 1)
 ElementC -> ElementIdentifier(ElementC.self, [optional key], 1)
 ```
 
 You will note that the identifiers remain stable, which ultimately ensures that views are reused.
 */
struct ElementIdentifier: Hashable, CustomDebugStringConvertible {
    
    let elementType : ObjectIdentifier
    let key : AnyHashable?
    let count : Int
    
    private let hash : Int
    
    init(element : Element, key : AnyHashable?, count : Int) {
        self.init(elementType: type(of: element), key: key, count: count)
    }

    init(elementType : Element.Type, key : AnyHashable?, count : Int) {
        
        self.elementType = ObjectIdentifier(elementType)
        self.key = key
        
        self.count = count
        
        var hasher = Hasher()
        hasher.combine(self.elementType)
        hasher.combine(self.key)
        hasher.combine(self.count)
        self.hash = hasher.finalize()
    }
    
    var debugDescription: String {
        if let key = self.key {
            return "\(self.elementType).\(String(describing: key)).\(self.count)"
        } else {
            return "\(self.elementType).\(self.count)"
        }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.hash)
    }
    
    /// Internal type used to create `ElementIdentifier` instances during view hierarchy updates.
    struct Factory {
        
        init(elementCount : Int) {
            self.countsByKey = Dictionary(minimumCapacity: elementCount)
        }
        
        mutating func nextIdentifier(for element : Element, key : AnyHashable?) -> ElementIdentifier {
            self.nextIdentifier(for: type(of: element), key: key)
        }
                
        mutating func nextIdentifier(for type : Element.Type, key : AnyHashable?) -> ElementIdentifier {
                        
            let count = self.nextCount(for: type, key: key)
            
            return ElementIdentifier(
                elementType: type,
                key: key,
                count: count
            )
        }
        
        private var countsByKey : [Key:Int]
        
        mutating private func nextCount(for type : Element.Type, key : AnyHashable?) -> Int {
            
            let key = Key(
                elementType: ObjectIdentifier(type),
                key: key
            )
            
            let current = self.countsByKey[key, default: 1]
            
            self.countsByKey[key] = (current + 1)
            
            return current
        }
        
        private struct Key : Hashable {
            let elementType : ObjectIdentifier
            let key : AnyHashable?
        }
    }
}
