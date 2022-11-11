
/**
 An identifier used to uniquely identify elements during diff
 and update operations.

 The identifier has three parts:
 1) **The type** of the underlying element, represented by `elementType`.

 2) **The key.** This is an optional value provided by developers using Blueprint to further
 disambiguate identical elements within a hierarchy. This is optional, and is rarely provided.
 When it is provided, `elementType` + ` key` is used to disambiguate elements.

 3) **The occurrence count** of that type of `elementType` + `key` in the hierarchy.
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
final class ElementIdentifier: Hashable, CustomDebugStringConvertible {

    private let elementType: Element.Type
    private let key: AnyHashable?
    private let count: Int
    
    private let hash: Int

    private static var cachedIdentifiers: [ObjectIdentifier: [Int: ElementIdentifier]] = [:]

    static func identifier(for element: Element, key: AnyHashable?, count: Int) -> ElementIdentifier {
        .identifier(for: type(of: element), key: key, count: count)
    }

    static func identifier(for elementType: Element.Type, key: AnyHashable?, count: Int) -> ElementIdentifier {

        /// There's no performance benefit to caching identifiers that have
        /// a key because the lookup ends up being more expensive, so
        /// just return a brand new identifier type.
        guard key == nil else {
            return ElementIdentifier(elementType: elementType, key: key, count: count)
        }

        let typeID = ObjectIdentifier(elementType)

        if let id = cachedIdentifiers[typeID]?[count] {
            /// We have an existing identifier, return it.
            return id
        } else {
            /// We do not have an existing identifier, we need to make and store a new one.

            let id = ElementIdentifier(elementType: elementType, key: key, count: count)

            cachedIdentifiers[typeID, default: [:]][count] = id

            return id
        }
    }

    private init(elementType: Element.Type, key: AnyHashable?, count: Int) {

        self.elementType = elementType
        self.key = key
        self.count = count

        var hasher = Hasher()
        hasher.combine(ObjectIdentifier(self.elementType))
        hasher.combine(self.key)
        hasher.combine(self.count)
        hash = hasher.finalize()
    }

    var debugDescription: String {
        if let key = key {
            return "\(elementType).\(String(describing: key)).\(count)"
        } else {
            return "\(elementType).\(count)"
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(hash)
    }

    static func == (lhs: ElementIdentifier, rhs: ElementIdentifier) -> Bool {
        lhs === rhs ||
            lhs.elementType == rhs.elementType &&
            lhs.key == rhs.key &&
            lhs.count == rhs.count
    }

    /// Internal type used to create `ElementIdentifier` instances during view hierarchy updates.
    struct Factory {

        init(elementCount: Int) {
            countsByKey = Dictionary(minimumCapacity: elementCount)
        }

        mutating func nextIdentifier(for element: Element, key: AnyHashable?) -> ElementIdentifier {
            let type = type(of: element)
            let count = nextCount(for: type, key: key)
            return ElementIdentifier(
                elementType: type,
                key: key,
                count: count
            )
        }

        private var countsByKey: [Key: Int]

        private mutating func nextCount(for type: Element.Type, key: AnyHashable?) -> Int {

            let key = Key(
                elementType: ObjectIdentifier(type),
                key: key
            )

            let current = countsByKey[key, default: 1]

            countsByKey[key] = (current + 1)

            return current
        }

        private struct Key: Hashable {

            let elementType: ObjectIdentifier
            let key: AnyHashable?
        }
    }
}
