//
//  Stateful.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 6/28/20.
//

import Foundation


protocol StatefulElementProperty {}


@propertyWrapper
public struct Stateful<Value> : StatefulElementProperty {
    
    private var initialValue : Value
    
    public var wrappedValue : Value {
        get {
            return self.liveStorage?.value ?? self.initialValue
        }
        
        nonmutating set {
            guard let storage = self.liveStorage else {
                fatalError("Cannot set ElementState's value outside of initialization, or element building.")
            }
            
            storage.value = newValue
        }
    }
    
    public var projectedValue : Binding<Value> {
        fatalError()
    }
    
    internal var liveStorage : StatefulStorage<Value>?
    
    public init(wrappedValue : Value) {
        self.initialValue = wrappedValue
    }
    
    public init(_ wrappedValue : Value) {
        self.initialValue = wrappedValue
    }
}

protocol AnyStatefulStorage : AnyObject
{
    var valueDidChange : () -> () { get set }
    
    var anyValue : Any { get set }
}

final class StatefulStorage<Value> : AnyStatefulStorage {
    
    var value : Value {
        didSet(oldValue) {
            guard self.isValueEqual(to: oldValue) == false else {
                return
            }
            
            self.valueDidChange()
        }
    }
    
    init(_ value : Value) {
        self.value = value
        self.valueDidChange = {}
    }
    
    // MARK: AnyStatefulStorage
    
    var valueDidChange : () -> ()
    
    var anyValue: Any {
        get { self.value }
        set { self.value = newValue as! Value } // TODO: This will trigger valueDidChange; it shouldnt.
    }
}


extension StatefulStorage {
    func isValueEqual(to other : Value) -> Bool {
        false
    }
}


extension StatefulStorage where Value : Equatable {
    func isValueEqual(to other : Value) -> Bool {
        value == other
    }
}


@propertyWrapper
public struct Binding<Value> : StatefulElementProperty {
    public var wrappedValue : Value
    
    public init(_ value : Value) {
        self.wrappedValue = value
    }
    
    func update() {
        
    }
}
