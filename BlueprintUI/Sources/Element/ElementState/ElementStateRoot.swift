import Foundation


final class ElementStateRoot {

    private var storage: [ElementPath: ElementState] = [:]

    subscript(_ path: ElementPath) -> ElementState {
        if let existing = storage[path] {
            return existing
        } else {
            let new = ElementState()
            storage[path] = new
            return new
        }
    }

    func perform<Return>(_ perform: () throws -> Return) rethrows -> Return {

        // Before we iterate, mark everything as not visited,
        // so the items we don't visit (aka removed elements)
        // can be GC'd afterwards.
        storage.forEach {
            $1.visited = false
        }

        defer {
            // Garbage collect all now removed elements
            storage.removeAll {
                $1.visited == false
            }
        }

        return try autoreleasepool {
            try perform()
        }
    }
}


final class ElementState {

    fileprivate var visited: Bool = true

    private(set) var readEnvironmentValues: Environment.ReadValues = .init()

    private var cacheInvalidationValue: CacheInvalidationValue?
    private var cache: [ObjectIdentifier: Any] = [:]

    subscript<Key: ElementStateCacheKey>(cache key: Key.Type) -> Key.Value {
        let id = ObjectIdentifier(key)

        if let existing = cache[id] {
            return existing as! Key.Value
        } else {
            let empty = Key.defaultValue
            cache[id] = empty
            return empty
        }
    }

    func perform<Return>(
        cacheInvalidationValue: (any Equatable)?,
        in environment: Environment,
        perform: (Environment) throws -> Return
    ) rethrows -> Return {

        var environment = environment
        let newInvalidationValue = CacheInvalidationValue(value: cacheInvalidationValue)

        if self.cacheInvalidationValue != newInvalidationValue {
            clearCacheValues()
        } else if environment.valuesEqual(to: readEnvironmentValues) == false {
            clearCacheValues()
        }

        var readKeys: Set<Environment.StorageKey> = []

        environment.subscribeToReads {
            readKeys.insert($0)
        }

        defer {
            self.readEnvironmentValues = environment.subset(with: readKeys)
            self.cacheInvalidationValue = newInvalidationValue
        }

        return try perform(environment)
    }

    private func clearCacheValues() {
        /// The same values will probably come back, so keep the capacity
        cache.removeAll(keepingCapacity: true)
    }

    private struct CacheInvalidationValue: Equatable {

        private var value: any Equatable

        init?(value: (any Equatable)?) {
            guard let value else {
                return nil
            }

            self.value = value
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.value.isEqual(rhs.value)
        }
    }
}


protocol ElementStateCacheKey {

    associatedtype Value

    static var defaultValue: Value { get }
}


extension Equatable {

    fileprivate func isEqual(_ other: any Equatable) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return self == other
    }

}

extension Dictionary {

    // Huh this isn't built in?
    fileprivate mutating func removeAll(where remove: (Key, Value) -> Bool) {
        for (key, value) in self {
            if remove(key, value) {
                removeValue(forKey: key)
            }
        }
    }
}
