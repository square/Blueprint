/// Result builder for working with elements that conform to `ElementBuilderChild`.
public typealias ElementBuilder<Child> = Builder<Child> where Child: ElementBuilderChild

extension ElementBuilder {
    /// Allow an Element to be implicitly converted into `Child`.
    public static func buildExpression(_ element: Element) -> Children {
        [Child(element)]
    }

    /// Allow an Optional Element to be unwrapped and implicitly converted into `Child`.
    public static func buildExpression(_ child: Element?) -> Children {
        guard let child = child else { return [] }
        return [Child(child)]
    }

    /// Allow Elements to be implicitly converted into `Child`.
    public static func buildExpression(_ elements: [Element]) -> Children {
        elements.map(Child.init)
    }
}

/// Defines a way for an`Element` to be implicitly converted into the conforming type (the child of a container).
/// In practice, this allows us to pass an `Element` directly into the result builder without manually converting to `Child` (i.e. Converting `Element` -> `StackLayout.Child`.
public protocol ElementBuilderChild {
    init(_ element: Element)
}
