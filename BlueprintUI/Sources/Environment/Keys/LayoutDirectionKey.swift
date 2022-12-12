import UIKit

extension Environment {
    public enum LayoutDirection: Hashable {
        case leftToRight
        case rightToLeft

        init(_ direction: UIUserInterfaceLayoutDirection) {
            switch direction {
            case .leftToRight:
                self = .leftToRight
            case .rightToLeft:
                self = .rightToLeft
            @unknown default:
                self = .leftToRight
            }
        }
    }

    private enum LayoutDirectionKey: EnvironmentKey {
        static var defaultValue: LayoutDirection {
            // This will be updated in BlueprintView.makeEnvironment()
            .leftToRight
        }
    }

    /// The layout direction associated with the current environment.
    public var layoutDirection: LayoutDirection {
        get { self[LayoutDirectionKey.self] }
        set { self[LayoutDirectionKey.self] = newValue }
    }
}
