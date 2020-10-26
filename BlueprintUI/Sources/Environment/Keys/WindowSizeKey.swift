import UIKit

extension Environment {
    private enum WindowSizeKey: EnvironmentKey {
        static var defaultValue: CGSize? {
            nil
        }
    }

    /// The size of the window that contains the hosting `BlueprintView`.
    /// Defaults to `nil` if the hosting view is not in a window.
    public var windowSize: CGSize? {
        get { self[WindowSizeKey.self] }
        set { self[WindowSizeKey.self] = newValue }
    }
}
