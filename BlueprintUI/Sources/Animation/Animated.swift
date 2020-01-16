//
//  Animated.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 4/6/20.
//

import Foundation


/**
 
 */
public struct Animated : Element {
    
    /**
     
     */
    public var animated : Bool
    
    /**
     
     */
    public var wrapped : Element
   
    /**
     
     */
    public init(animated : Bool, wrapping element : Element) {
        
        self.animated = animated
        self.wrapped = element
    }
    
    //
    // MARK: Element
    //
    
    public var content: ElementContent {
        ElementContent(child: self.wrapped)
    }
    
    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        ViewDescription(AnimatedView.self) {
            $0.builder = { AnimatedView(frame: bounds) }
            $0.allowsAnimations = self.animated
        }
    }
    
    final class AnimatedView : UIView {}
}

