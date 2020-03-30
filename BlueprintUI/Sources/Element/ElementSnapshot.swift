//
//  ElementSnapshot.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 3/29/20.
//

import Foundation


internal final class ElementSnapshot {
    
    var element : Element
    var environment : Environment
    
    var content : ElementContent
    var children : [ElementSnapshot]
    
    init(
        element : Element,
        parentEnvironment : Environment
    ) {
        let (element, environment) = element.updatedElement(with: parentEnvironment)
        
        self.element = element
        self.environment = environment
        
        self.content = self.element.content
        
    }
}
