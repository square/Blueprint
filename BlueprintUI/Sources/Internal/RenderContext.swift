import Foundation

/// Stores info about the currently running render pass, if there is one.
///
/// The render context is available statically, which allows "out of band" operations like
/// calls to ``ElementContent/measure(in:environment:)`` to get some context without having it
/// passed in explicitly. This depends entirely on the render pass running exclusively on the main
/// thread.
struct RenderContext {
    /// The current render context, if there is one.
    private(set) static var current: Self?

    var layoutMode: LayoutMode

    /// Perform the given block with this as the current render context, restoring the previous
    /// context before returning.
    func perform<Result>(block: () throws -> Result) rethrows -> Result {
        let previous = Self.current
        defer { Self.current = previous }

        Self.current = self

        return try block()
    }
}
