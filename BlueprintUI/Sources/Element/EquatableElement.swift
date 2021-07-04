//
//  EquatableElement.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 7/3/21.
//

import Foundation



public protocol EquatableElement : AnyEquatableElement {
    
    func isEquivalent(to other : Self) -> Bool
    
}


public protocol AnyEquatableElement : Element {
 
    func anyIsEquivalentTo(other : AnyEquatableElement) -> Bool
    
}


public extension EquatableElement {
    
    func anyIsEquivalentTo(other: AnyEquatableElement) -> Bool {
        guard let other = other as? Self else { return false }
        
        return self.isEquivalent(to: other)
    }
}


public extension EquatableElement where Self:Equatable {
    
    func isEquivalent(to other : Self) -> Bool {
        self == other
    }
}
