//
//  Debugging.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 4/21/20.
//

import Foundation


public struct DebuggingOptions : Equatable {
    
    public var isEnabled : Bool
    
    public var showElementFrames : ShowElementFrames
    public var longPressForDebugger : Bool
    public var exploreElementHistory : Bool
    
    // TODO remove
    public var isIn3DPreview : Bool = false
    
    public init(
        isEnabled : Bool = false,
        showElementFrames : ShowElementFrames = .none,
        longPressForDebugger : Bool = false,
        exploreElementHistory : Bool = false
    )
    {
        self.isEnabled = isEnabled
        
        self.showElementFrames = showElementFrames
        self.longPressForDebugger = longPressForDebugger
        self.exploreElementHistory = exploreElementHistory
    }
}


public extension DebuggingOptions {
    enum ShowElementFrames : Equatable {
        case none
        case all
        case viewBacked
    }
}
