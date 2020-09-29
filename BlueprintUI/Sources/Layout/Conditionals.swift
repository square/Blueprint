//
//  Conditionals.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 9/22/20.
//


extension Element {
    
    //
    // MARK: If / Else
    //
    
    func `if`(
        _ isTrue : Bool,
        modify : (Self) -> Element
    ) -> Element
    {
        if isTrue {
            return modify(self)
        } else {
            return self
        }
    }
    
    func `if`(
        _ isTrue : Bool,
        then : (Self) -> Element,
        else : (Self) -> Element
    ) -> Element
    {
        if isTrue {
            return then(self)
        } else {
            return `else`(self)
        }
    }
    
    //
    // MARK: If Let
    //
    
    func `ifLet`<Value>(
        _ value : Value?,
        modify : (Value, Self) -> Element
    ) -> Element
    {
        if let value = value {
            return modify(value, self)
        } else {
            return self
        }
    }
    
    func `ifLet`<Value>(
        _ value : Value?,
        then : (Value, Self) -> Element,
        else : (Self) -> Element
    ) -> Element
    {
        if let value = value {
            return then(value, self)
        } else {
            return `else`(self)
        }
    }
    
    //
    // MARK: Modify
    //
    
    func modify(_ modify : (inout Self) -> ()) -> Element
    {
        var copy = self
        
        modify(&copy)
        
        return copy
    }
    
    func modify(_ modify : (Self) -> Element) -> Element
    {
        modify(self)
    }
}
