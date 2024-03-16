import BlueprintUI
import UIKit

/// Conform to this protocol to handle links tapped in an `AttributedLabel`.
///
/// Use the `URLHandlerEnvironmentKey` or `Environment.urlHandler` property to override
/// the link handler in the environment.
///
public protocol URLHandler {
    func onTap(url: URL)
}

class NullURLHandler: URLHandler {
    func onTap(url: URL) {}
}

class DefaultURLHandler: NullURLHandler {
    @available(iOSApplicationExtension, unavailable)
    override func onTap(url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
}
