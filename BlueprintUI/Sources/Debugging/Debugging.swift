//
//  Debugging.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 4/21/20.
//

import Foundation


public struct Debugging : Equatable {
    
    public var showElementFrames : ShowElementFrames
    
    public var isIn3DPreview : Bool = false
    
    public enum ShowElementFrames : Equatable {
        case none
        case all
        case viewBacked
    }
    
    public var longPressForDebugger : Bool
    public var exploreElementHistory : Bool
    
    public init(
        showElementFrames : ShowElementFrames = .none,
        longPressForDebugger : Bool = false,
        exploreElementHistory : Bool = false
    )
    {
        self.showElementFrames = showElementFrames
        self.longPressForDebugger = longPressForDebugger
        self.exploreElementHistory = exploreElementHistory
    }
}
