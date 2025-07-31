import BlueprintUI
import UIKit

/// Conform to this protocol to handle links tapped in an `AttributedLabel`.
///
/// Use the `URLHandlerEnvironmentKey` or `Environment.urlHandler` property to override
/// the link handler in the environment.
///
public protocol URLHandler {
    func onTap(url: URL)

    func isEquivalent(to other: Self) -> Bool
}

struct NullURLHandler: URLHandler {
    func onTap(url: URL) {}

    func isEquivalent(to other: NullURLHandler) -> Bool {
        true
    }
}

struct DefaultURLHandler: URLHandler {

    @available(iOSApplicationExtension, unavailable)
    func onTap(url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func isEquivalent(to other: DefaultURLHandler) -> Bool {
        true
    }
}

public struct URLHandlerEnvironmentKey: EnvironmentKey {

    public static let defaultValue: URLHandler = {
        // This is our best guess for "is this executable an extension?"
        if let _ = Bundle.main.infoDictionary?["NSExtension"] {
            return NullURLHandler()
        } else if Bundle.main.bundlePath.hasSuffix(".appex") {
            return NullURLHandler()
        } else {
            return DefaultURLHandler()
        }
    }()

    public static func isEquivalent(_ lhs: any URLHandler, _ rhs: any URLHandler) -> Bool {
        false
    }
}

extension Environment {
    /// The link handler to use to open links tapped in an `AttributedLabel`.
    public var urlHandler: URLHandler {
        get { self[URLHandlerEnvironmentKey.self] }
        set { self[URLHandlerEnvironmentKey.self] = newValue }
    }
}

struct ClosureURLHandler: URLHandler {
    var onTap: (URL) -> Void

    func onTap(url: URL) {
        onTap(url)
    }

    func isEquivalent(to other: ClosureURLHandler) -> Bool {
        /// We don't know what's in the closure, so we're always false.
        false
    }
}
