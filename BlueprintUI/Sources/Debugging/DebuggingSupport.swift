//
//  DebuggingSupport.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 4/21/20.
//

import Foundation


public struct DebuggingSupport {
    public static var viewDescriptionProvider : (ViewDescription?, Element, CGRect, DebuggingOptions) -> ViewDescription? = { description, _, _, _ in
        return description
    }
}


@objc public protocol DebuggingSetup {
    static func setup()
}


public protocol DebuggingSelectionManagerContainer : UIView {
    var selectionManager : DebuggingSelectionManager { get }
}

public protocol DebuggingSelectionManager {
    
}


extension Notification.Name {
    public static var BlueprintGlobalDebuggingSettingsChanged = Notification.Name("BlueprintGlobalDebuggingSettingsChanged")
}
