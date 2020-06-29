//
//  Stateful.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 6/28/20.
//

import Foundation


protocol AnyStatefulElementProperty {
    
}


protocol StatefulElementProperty {
    
    associatedtype Value
    
    var wrappedValue : Value { get set }
    
    mutating func setLiveStorage(_ liveStorage : AnyStatefulStorage)
}


@propertyWrapper
public struct Stateful<Value> : StatefulElementProperty, AnyStatefulElementProperty {
    
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
        guard let storage = self.liveStorage else {
            fatalError("Cannot access the projectedValue of a state outside of element building.")
        }
        
        return Binding(storage)
    }
    
    var liveStorage : StatefulStorage<Value>?
    
    public init(wrappedValue : Value) {
        self.initialValue = wrappedValue
    }
    
    public init(_ wrappedValue : Value) {
        self.initialValue = wrappedValue
    }
    
    // MARK: StatefulElementProperty
    
    mutating func setLiveStorage(_ liveStorage : AnyStatefulStorage)
    {
        self.liveStorage = (liveStorage as! StatefulStorage<Value>)
    }
}


@propertyWrapper
public struct Binding<Value> : StatefulElementProperty, AnyStatefulElementProperty {
    
    public var wrappedValue : Value {
        get {
            self.liveStorage.value
        }
        
        nonmutating set {
            self.liveStorage.value = newValue
        }
    }
    
    public var projectedValue : Binding<Value> {
        self
    }
    
    var liveStorage : StatefulStorage<Value>
    
    init(_ liveStorage : StatefulStorage<Value>) {
        self.liveStorage = liveStorage
    }
    
    // MARK: StatefulElementProperty
    
    mutating func setLiveStorage(_ liveStorage : AnyStatefulStorage)
    {
        fatalError()
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
