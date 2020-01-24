/// Represents a path into an element hierarchy.
/// Used for disambiguation during diff operations.
struct ElementPath: Hashable {
    
    private var storage: Storage
    
    init() {
        storage = Storage(components: [])
    }
    
    private mutating func storageForWriting() -> Storage {
        if !isKnownUniquelyReferenced(&storage) {
            storage = Storage(components: storage.components)
        }
        return storage
    }

    var components: [Component] {
        return storage.components
    }
    
    mutating func prepend(component: Component) {
        storageForWriting().prepend(component: component)
    }
    
    mutating func append(component: Component) {
        storageForWriting().append(component: component)
    }
    
    func prepending(component: Component) -> ElementPath {
        var result = self
        result.prepend(component: component)
        return result
    }
    
    func appending(component: Component) -> ElementPath {
        var result = self
        result.append(component: component)
        return result
    }

    static var empty: ElementPath {
        return ElementPath()
    }
}

extension ElementPath {

    /// Represents an element in a hierarchy.
    struct Component: Hashable, CustomDebugStringConvertible {

        /// The type of element represented by this component.
        var elementType: Element.Type

        /// The identifier of this component.
        var identifier: ElementIdentifier
        
        init(elementType: Element.Type, identifier: ElementIdentifier) {
            self.elementType = elementType
            self.identifier = identifier
        }
        
        static func ==(lhs: Component, rhs: Component) -> Bool {
            return lhs.elementType == rhs.elementType
                && lhs.identifier == rhs.identifier
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(ObjectIdentifier(elementType))
            hasher.combine(identifier)
        }

        // MARK: CustomDebugStringConvertible
        
        var debugDescription: String {
            return "\(self.elementType).\(self.identifier)"
        }
    }
}

extension ElementPath {
    
    fileprivate final class Storage: Hashable, CustomDebugStringConvertible {
        
        private var _hash: Int? = nil
        
        private (set) var components: [ElementPath.Component] {
            didSet {
                _hash = nil
            }
        }
        
        init(components: [ElementPath.Component]) {
            self.components = components
        }
        
        func append(component: ElementPath.Component) {
            components.append(component)
        }
        
        func prepend(component: ElementPath.Component) {
            components.insert(component, at: 0)
        }

        func hash(into hasher: inout Hasher) {
            if _hash == nil {
                _hash = components.hashValue
            }
            hasher.combine(_hash)
        }
        
        static func ==(lhs: Storage, rhs: Storage) -> Bool {
            return lhs.components == rhs.components
        }
        
        // MARK: CustomDebugStringConvertible
        
        var debugDescription: String {
            return self.components.map { $0.debugDescription }.joined()
        }
    }
}

