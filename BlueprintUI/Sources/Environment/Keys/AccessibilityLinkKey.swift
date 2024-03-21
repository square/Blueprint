import UIKit

extension Environment {
    private enum LinkAccesibilityLabelKey: EnvironmentKey {
        static var defaultValue: String? {
            UIImage(systemName: "link")?.accessibilityLabel
        }
    }

    /// The localised accessibility label elements should use when handling links.
    ///
    /// Defaults to `UIImage(systemName: "link")?.accessibilityLabel`.
    public var linkAccessibilityLabel: String? {
        get { self[LinkAccesibilityLabelKey.self] }
        set { self[LinkAccesibilityLabelKey.self] = newValue }
    }
}
