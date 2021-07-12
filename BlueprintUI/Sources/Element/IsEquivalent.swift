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
    
    public static func comparing(_ lhs : Value, _ rhs : Value, using : (inout Self) -> ()) throws -> Bool {
        let check = Self(using)
        return try check.compare(lhs, rhs)
    }
    
    public func compare(_ lhs : Value, _ rhs : Value) throws -> Bool {
        for comparison in self.comparisons {
            if try comparison(lhs, rhs) == false {
                #if DEBUG
                // TODO: Throw ComparableElementNotEquivalent with keypath and values
                return false
                #else
                return false
                #endif
            }
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
            try lhs[keyPath: keyPath].isEquivalent(to: rhs[keyPath: keyPath])
        })
    }
    
    mutating public func add(_ keyPath : KeyPath<Value, AnyComparableElement>) {
        self.comparisons.append({ lhs, rhs in
            try lhs[keyPath: keyPath].anyIsEquivalent(to: rhs[keyPath: keyPath])
        })
    }
    
    mutating public func add(_ keyPath : KeyPath<Value, Element>) {
        self.comparisons.append({ lhs, rhs in
            try ElementState.elementsEquivalent(lhs[keyPath: keyPath], rhs[keyPath: keyPath])
        })
    }
    
    mutating public func add(_ keyPath : KeyPath<Value, Element?>) {
        self.comparisons.append({ lhs, rhs in
            try ElementState.elementsEquivalent(lhs[keyPath: keyPath], rhs[keyPath: keyPath])
        })
    }
    
    private var comparisons : [(Value, Value) throws -> Bool] = []
}


