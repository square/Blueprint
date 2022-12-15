//
//  AttributedLabel+Environment.swift
//  BlueprintUICommonControls
//
//  Created by Kyle Bashour on 12/16/21.
//

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
    public static var defaultValue: URLHandler = DefaultURLHandler()
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
