/// Generic result builder for converting blocks of `Child...` into `[Child]`.
@_functionBuilder // change to @resultBuilder when we upgrade to Swift 5.4.
public struct Builder<Child> {
    /// Function builder for converting blocks of `Child...` into `[Child]`.
    /// - Parameter children: All children.
    /// - Returns: `[Child]`.
    public static func buildBlock(_ children: Child...) -> [Child] {
        return children
    }
}
