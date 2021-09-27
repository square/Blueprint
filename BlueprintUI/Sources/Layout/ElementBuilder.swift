/// Generic result builder for converting blocks of `Child...` into `[Child]`.
@resultBuilder
public struct ElementBuilder<Child: ElementBuilderChild> {
    public typealias Children = [Child]

    public static func buildBlock(_ elements: Children...) -> Children {
        elements.flatMap { $0 }
    }

    public static func buildOptional(_ elements: Children?) -> Children {
        elements ?? []
    }

    public static func buildEither(first: Children) -> Children {
        first
    }

    public static func buildEither(second: Children) -> Children {
        second
    }

    public static func buildExpression(_ element: Child) -> Children {
        [element]
    }

    /// Allow for an array of `Child` to be flattened into the overall result.
    public static func buildExpression(_ elements: [Child]) -> Children {
        elements
    }

    /// Allow an Element to be implicitly converted into `Child`.
    public static func buildExpression(_ element: Element) -> Children {
        [Child(element)]
    }

    /// Allow Elements to be implicitly converted into `Child`.
    public static func buildExpression(_ elements: [Element]) -> Children {
        elements.map(Child.init)
    }
}

/// Defines a way for an`Element` to be implicitly converted into the conforming type (the child of a container).
/// In practive, this allows us to pass an `Element` directly into the result builder without manually converting to `Child` (i.e. Converting `Element` -> `StackLayout.Child`.
public protocol ElementBuilderChild {
    init(_ element: Element)
}
