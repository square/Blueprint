import UIKit

extension Environment {
    private enum LinkAccesibilityLabelKey: EnvironmentKey {
        static var defaultValue: String? {
            UIImage(systemName: "link")?.accessibilityLabel
        }

        static func isEquivalent(lhs: String?, rhs: String?, in context: EquivalencyContext) -> Bool {
            equivalentInLayout(lhs: lhs, rhs: rhs, in: context)
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
