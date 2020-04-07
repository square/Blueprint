/// Represents a path into an element hierarchy.
/// Used for disambiguation during diff operations.
struct ElementPath: Hashable {
    
    private var storage: Storage
    
    init() {
        storage = Storage(identifiers: [])
    }
    
    private mutating func storageForWriting() -> Storage {
        if !isKnownUniquelyReferenced(&storage) {
            storage = Storage(identifiers: storage.identifiers)
        }
        
        return storage
    }

    var identifiers: [ElementIdentifier] {
        return storage.identifiers
    }
    
    mutating func prepend(identifier: ElementIdentifier) {
        storageForWriting().prepend(identifier: identifier)
    }
    
    mutating func append(identifier: ElementIdentifier) {
        storageForWriting().append(identifier: identifier)
    }
    
    func prepending(identifier: ElementIdentifier) -> ElementPath {
        var result = self
        result.prepend(identifier: identifier)
        return result
    }
    
    func appending(identifier: ElementIdentifier) -> ElementPath {
        var result = self
        result.append(identifier: identifier)
        return result
    }

    static var empty: ElementPath {
        return ElementPath()
    }
}


extension ElementPath {
    
    fileprivate final class Storage: Hashable, CustomDebugStringConvertible {
        
        private var _hash: Int? = nil
        
        private (set) var identifiers: [ElementIdentifier] {
            didSet {
                _hash = nil
            }
        }
        
        init(identifiers: [ElementIdentifier]) {
            self.identifiers = identifiers
        }
        
        func append(identifier: ElementIdentifier) {
            identifiers.append(identifier)
        }
        
        func prepend(identifier: ElementIdentifier) {
            identifiers.insert(identifier, at: 0)
        }

        func hash(into hasher: inout Hasher) {
            if _hash == nil {
                _hash = identifiers.hashValue
            }
            
            hasher.combine(_hash)
        }
        
        static func ==(lhs: Storage, rhs: Storage) -> Bool {
            return lhs.identifiers == rhs.identifiers
        }
        
        // MARK: CustomDebugStringConvertible
        
        var debugDescription: String {
            return self.identifiers.map { $0.debugDescription }.joined()
        }
    }
}

