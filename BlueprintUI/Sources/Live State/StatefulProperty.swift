//
//  StatefulProperty.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 6/27/20.
//

import UIKit


protocol StatefulElementProperty
{
    
}

extension Element {
    func statefulElementProperties() -> [(String, StatefulElementProperty)]
    {
        let mirror = Mirror(reflecting: self)
        
        var result = [(String, StatefulElementProperty)]()
        
        for child in mirror.children {
            if let name = child.label, let property = child.value as? StatefulElementProperty {
                result.append((name, property))
            }
        }
        
        return result
    }
}


@propertyWrapper
public struct ElementState<Value> : StatefulElementProperty {
    
    private let initialValue : Value
    
    public var wrappedValue : Value {
        get {
            return storage?.value ?? self.initialValue
        }
        
        nonmutating set {
            self.storage?.value = newValue
        }
    }
    
    internal var storage : Storage?
    
    public init(wrappedValue : Value) {
        self.initialValue = wrappedValue
    }
    
    final internal class Storage {
        var value : Value
        
        init(_ value : Value) {
            self.value = value
        }
    }
}

// https://github.com/Zewo/Reflection/
// https://forums.swift.org/t/state-messing-with-initializer-flow/25276/18



@propertyWrapper
public struct Binding<Value> : StatefulElementProperty {
    public var wrappedValue : Value
    
    public init(_ value : Value) {
        self.wrappedValue = value
    }
    
    func update() {
        
    }
}

