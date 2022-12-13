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

        init(_ direction: UITraitEnvironmentLayoutDirection) {
            switch direction {
            case .leftToRight:
                self = .leftToRight
            case .rightToLeft:
                self = .rightToLeft
            case .unspecified:
                self = .leftToRight
            @unknown default:
                self = .leftToRight
            }
        }
    }

    private enum LayoutDirectionKey: EnvironmentKey {
        static var defaultValue: LayoutDirection {
            LayoutDirection(UITraitCollection.current.layoutDirection)
        }
    }

    /// The layout direction associated with the current environment.
    public var layoutDirection: LayoutDirection {
        get { self[LayoutDirectionKey.self] }
        set { self[LayoutDirectionKey.self] = newValue }
    }
}
