/// Generic result builder for converting blocks of `Child...` into `[Child]`.
@_functionBuilder // change to @resultBuilder when we upgrade to Swift 5.4.
public struct ElementBuilder {
    /// Function builder for converting blocks of `Child...` into `[Child]`.
    /// - Parameter children: All children.
    /// - Returns: `[Child]`.
    public static func buildBlock(_ elements: Element...) -> [Element] {
        elements.map { element -> [Element] in
            if let many = element as? ElementContainer {
                return many.elements
            } else {
                return [element]
            }
        }.flatMap { $0 }
    }

    public static func buildOptional(_ elements: [Element]?) -> Element {
        ElementContainer(elements: elements ?? [])
    }

    public static func buildEither(first: [Element]) -> Element {
        ElementContainer(elements: first)
    }

    public static func buildEither(second: [Element]) -> Element {
        ElementContainer(elements: second)
    }
}

private struct ElementContainer: ProxyElement {
    var elements: [Element]
    var elementRepresentation: Element {
        fatalError("This type should never render. It should only be used to contain other Elements.")
    }
}
