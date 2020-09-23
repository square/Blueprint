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
        modify : (inout Self) -> ()
    ) -> Element
    {
        if isTrue {
            var copy = self
            modify(&copy)
            return copy
        } else {
            return self
        }
    }
    
    func `if`(
        _ isTrue : Bool,
        onTrue : (inout Self) -> (),
        onFalse : (inout Self) -> ()
    ) -> Element
    {
        var copy = self
        
        if isTrue {
            onTrue(&copy)
        } else {
            onFalse(&copy)
        }
        
        return copy
    }
    
    //
    // MARK: If Let
    //
    
    func `ifLet`<Value>(
        _ value : Value?,
        modify : (Value, inout Self) -> ()
    ) -> Element
    {
        if let value = value {
            var copy = self
            modify(value, &copy)
            return copy
        } else {
            return self
        }
    }
    
    func `ifLet`<Value>(
        _ value : Value?,
        hadValue : (Value, inout Self) -> (),
        nilValue : (inout Self) -> ()
    ) -> Element
    {
        var copy = self
        
        if let value = value {
            hadValue(value, &copy)
        } else {
            nilValue(&copy)
        }
        
        return copy
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
}
