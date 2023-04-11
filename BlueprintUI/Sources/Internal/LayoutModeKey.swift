import Foundation

enum LayoutModeKey: EnvironmentKey {
    static var defaultValue: LayoutMode { .default }
}

extension Environment {
    /// This mode will be inherited by descendant BlueprintViews that do not have an explicit
    /// mode set.
    public internal(set) var layoutMode: LayoutMode {
        get { self[LayoutModeKey.self] }
        set { self[LayoutModeKey.self] = newValue }
    }
}
