//
//  DebuggingSupport.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 4/21/20.
//

import Foundation


public struct DebuggingSupport {
    public static var viewDescriptionProvider : (ViewDescription?, Element, CGRect, Debugging) -> ViewDescription? = { description, _, _, _ in
        return description
    }
}


@objc public protocol DebuggingSetup {
    static func setup()
}


extension Notification.Name {
    public static var BlueprintGlobalDebuggingSettingsChanged = Notification.Name("BlueprintGlobalDebuggingSettingsChanged")
}
