//
//  ElementStateTree.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 6/24/21.
//

import Foundation


final class ElementStateTree {
    
    var states : [ElementIdentifier:ElementState] = [:]
    
    func state(for identifier : ElementIdentifier) -> ElementState {
        fatalError()
    }
    
    func state(for path : ElementPath) -> ElementState {
        fatalError()
    }
}


extension ElementStateTree {
    
    final class ElementState {
        
        var state : Any
        
        var children : ElementStateTree
        
    }
}
