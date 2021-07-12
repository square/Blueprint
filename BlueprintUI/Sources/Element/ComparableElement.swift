//
//  ComparableElement.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 7/3/21.
//

import Foundation


/// An `ComparableElement` is an element which can cache its
/// measurements and layouts across layout passes in order to dramatically improve
/// performance of repeated layouts.
///
/// Many element types within Blueprint already conform to `ComparableElement`.
/// If your element can be easily compared for equality, consider making your
/// it conform to `ComparableElement` for improved performance across layouts.
public protocol ComparableElement : AnyComparableElement {
    
    ///
    /// Indicates if the element is equivalent to the other provided element.
    /// Return true if the elements are the same, or return false if something about
    /// the element changed, such as its content or measurement attributes.
    ///
    /// Note that even if this method returns true, the `ViewDescription`
    /// backing the element will still be re-applied to the on-screen view.
    ///
    /// If your element conforms to `Equatable`, this method is synthesized automatically.
    ///
    func isEquivalent(to other : Self) throws -> Bool
    
    /// Return true if the layout and measurement caches should be cleared from the given size change.
    func willSizeChangeAffectLayout(from : CGSize, to : CGSize) -> Bool
    
    ///
    var appliesViewDescriptionIfEquivalent : Bool { get }
}


/// A type-erased version of `ComparableElement`, allowing the comparison
/// of two arbitrary elements, and allowing direct access to methods, without self or associated type constraints.
public protocol AnyComparableElement : Element {
 
    /// Returns true if the two elements are the same type, and are equivalent.
    func anyIsEquivalent(to other : AnyComparableElement) throws -> Bool
    
    /// Return true if the layout and measurement caches should be cleared from the given size change.
    func willSizeChangeAffectLayout(from : CGSize, to : CGSize) -> Bool
    
    ///
    var appliesViewDescriptionIfEquivalent : Bool { get }
}


public protocol KeyPathComparableElement : ComparableElement {
    
    static var isEquivalent : IsEquivalent<Self> { get }
}


public extension ComparableElement where Self:Equatable {
    
    func isEquivalent(to other : Self) -> Bool {
        self == other
    }
}


public extension ComparableElement where Self:KeyPathComparableElement {
    
    func isEquivalent(to other: Self) throws -> Bool {
        try Self.isEquivalent.compare(self, other)
    }
}


public extension ComparableElement {
    
    func anyIsEquivalent(to other: AnyComparableElement) throws -> Bool {
        guard let other = other as? Self else { return false }
        
        return try self.isEquivalent(to: other)
    }
    
    func willSizeChangeAffectLayout(from : CGSize, to : CGSize) -> Bool {
        true
    }
    
    var appliesViewDescriptionIfEquivalent : Bool {
        true
    }
}


public enum ComparableElementNotEquivalent : Error {
    case nonEquivalentValue(Any, Any, AnyKeyPath)
}


public extension Array where Self.Element == BlueprintUI.Element {
    
    func isEquivalent(to other : Self) throws -> Bool {
        
        guard self.count == other.count else { return false }
        
        for index in 0..<self.count {
            let lhs = self[index]
            let rhs = other[index]
            
            guard
                let lhs = lhs as? AnyComparableElement,
                let rhs = rhs as? AnyComparableElement
            else {
                return false
            }
            
            
            if try lhs.anyIsEquivalent(to: rhs) == false {
                return false
            }
        }
        
        return true
    }
}
