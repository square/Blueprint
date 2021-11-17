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

    @available(
        *,
        unavailable,
        message: "Optionals must be unwrapped with `if let value = ...` to be returned from a result builder."
    )
    public static func buildExpression(_ child: Child?) -> Children {

        /// This method ensures better compile-time error messages are shown when
        /// returning an `Optional` from a result builder. Without this method,
        /// when an `Optional` is returned from a result builder, the compiler
        /// will instead resolve the `configure`-based version of our component
        /// initializers, resulting in a confusing error message.
        ///
        /// Adding this explicit override ensures that the compiler continues to attempt to resolve
        /// the trailing closure as a result builder-based closure, and returns the above error message.

        fatalError()
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
}
