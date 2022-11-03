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

    func isEquivalent(to other: URLHandler) -> Bool
}

struct DefaultURLHandler: URLHandler {

    func onTap(url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    func isEquivalent(to other: URLHandler) -> Bool {
        guard other is Self else { return false }

        return true
    }
}

public struct URLHandlerEnvironmentKey: EnvironmentKey {

    public static func equals(_ lhs: URLHandler, _ rhs: URLHandler) -> Bool {
        lhs.isEquivalent(to: rhs)
    }

    public static let defaultValue: URLHandler = DefaultURLHandler()
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

    func isEquivalent(to other: URLHandler) -> Bool {
        false
    }
}
