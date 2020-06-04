import UIKit

extension Environment {
    private enum SafeAreaInsetsKey: EnvironmentKey {
        static let defaultValue = UIEdgeInsets.zero
    }

    /// The insets representing the safe area for content.
    public var safeAreaInsets: UIEdgeInsets {
        get { self[SafeAreaInsetsKey.self] }
        set { self[SafeAreaInsetsKey.self] = newValue }
    }
}
