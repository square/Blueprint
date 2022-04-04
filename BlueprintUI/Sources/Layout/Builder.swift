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

    public static func buildExpression(_ child: Child?) -> Children {
        guard let child = child else { return [] }
        return [child]
    }

    public static func buildArray(_ components: [Children]) -> Children {
        components.flatMap { $0 }
    }

    public static func buildArray(_ components: Children) -> Children {
        components
    }

    public static func buildLimitedAvailability(_ component: Children) -> Children {
        component
    }

    /// Allow for an array of `Child` to be flattened into the overall result.
    public static func buildExpression(_ children: [Child]) -> Children {
        children
    }

    /// Allow an escape hatch when the control flow requires an output (such as a `switch`).
    public static func buildExpression(_ children: None) -> Children {
        []
    }
}

/// Empty type that results in no children. This is useful when an expression requires output but no children are applicable (i.e. a switch statement).
/// Example:
/// ```
/// switch item {
/// case .first:
///    None()
/// case .second:
///     "2"
/// }
/// ```
public struct None {
    public init() {}
}
