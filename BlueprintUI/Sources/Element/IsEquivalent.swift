//
//  IsEquivalent.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 7/10/21.
//

import Foundation


public struct IsEquivalent<Value> {
    
    public init(_ configure : (inout Self) -> ()) {
        configure(&self)
    }
    
    public func compare(_ lhs : Value, _ rhs : Value) -> Bool {
        for comparison in self.comparisons {
            comparison(lhs, rhs)
        }
        
        return true
    }
    
    mutating public func add<Property:Equatable>(_ keyPath : KeyPath<Value, Property>) {
        self.comparisons.append({ lhs, rhs in
            lhs[keyPath: keyPath] == rhs[keyPath: keyPath]
        })
    }
    
    mutating public func add<Property:ComparableElement>(_ keyPath : KeyPath<Value, Property>) {
        self.comparisons.append({ lhs, rhs in
            lhs[keyPath: keyPath].isEquivalent(to: rhs[keyPath: keyPath])
        })
    }
    
    mutating public func add(_ keyPath : KeyPath<Value, AnyComparableElement>) {
        self.comparisons.append({ lhs, rhs in
            lhs[keyPath: keyPath].anyIsEquivalent(to: rhs[keyPath: keyPath])
        })
    }
    
    mutating public func add(_ keyPath : KeyPath<Value, Element>) {
        self.comparisons.append({ lhs, rhs in
            ElementState.elementsEquivalent(lhs[keyPath: keyPath], rhs[keyPath: keyPath])
        })
    }
    
    private var comparisons : [(Value, Value) -> Bool] = []
}


