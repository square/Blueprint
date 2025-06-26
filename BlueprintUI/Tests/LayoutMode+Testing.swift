import BlueprintUI

extension LayoutMode {
    static let testModes: [LayoutMode] = [.caffeinated]

    /// Run the given block with `self` as the default layout mode, restoring the previous default
    /// afterwards, and returning the result of the block.
    func performAsDefault<Result>(block: () throws -> Result) rethrows -> Result {
        let oldLayoutMode = LayoutMode.default
        defer { LayoutMode.default = oldLayoutMode }

        LayoutMode.default = self

        return try block()
    }
}
