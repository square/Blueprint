/// Generic result builder for converting blocks of `Child...` into `[Child]`.
@resultBuilder
public struct Builder<Child> {
    public typealias Children = [Child]

    public static func buildBlock(_ children: Children...) -> Children {
        children.flatMap { $0 }
    }

    public static func buildOptional(_ children: Children?) -> Children {
        children ?? []
    }

    public static func buildEither(first: Children) -> Children {
        first
    }

    public static func buildEither(second: Children) -> Children {
        second
    }

    public static func buildExpression(_ child: Child) -> Children {
        [child]
    }

    /// Allow for an array of `Child` to be flattened into the overall result.
    public static func buildExpression(_ children: [Child]) -> Children {
        children
    }
}
