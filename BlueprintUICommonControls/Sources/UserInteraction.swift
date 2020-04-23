//
//  UserInteraction.swift
//  BlueprintUICommonControls
//
//  Created by Kyle Van Essen on 4/22/20.
//

import BlueprintUI


public struct UserInteraction : ProxyElement {
    
    public var enabled : Bool
    public var wrapping : Element
    
    public init(enabled : Bool = true, wrapping : Element) {
        self.enabled = enabled
        self.wrapping = wrapping
    }
    
    public var elementRepresentation: Element {
        return self.wrapping
    }
    
    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        ViewDescription(View.self) {
            $0.builder = { View(frame: bounds) }
            
            $0.apply {
                $0.isUserInteractionEnabled = self.enabled
            }
        }
    }
    
    private final class View : UIView {}
}
