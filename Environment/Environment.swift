//
//  Environment.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 3/28/20.
//

import Foundation


public protocol EnvironmentKey {
    associatedtype Value

    static var defaultValue: Self.Value { get }
}


public struct Environment {
    public static let empty = Environment()

    internal init(_ configure : (inout Environment) -> () = { _ in}) {
        configure(&self)
    }

    private var values: [ObjectIdentifier: Any] = [:]

    public subscript<K>(key: K.Type) -> K.Value where K: EnvironmentKey {
        get {
            let objectId = ObjectIdentifier(key)

            if let value = values[objectId] as? K.Value {
                return value
            }

            return key.defaultValue
        }
        set {
            values[ObjectIdentifier(key)] = newValue
        }
    }
}
