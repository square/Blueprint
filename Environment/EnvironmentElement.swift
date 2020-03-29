//
//  EnvironmentElement.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 3/28/20.
//

import Foundation


public protocol EnvironmentElement : Element {
    var environment : Environment { get set }
    
    func editEnvironment(_ environment : inout Environment)
}


public extension EnvironmentElement {
    func editEnvironment(_ environment : inout Environment) {
        // Nothing by default.
    }
}

@propertyWrapper public struct ENV {
        
    public init() { }
    
    public var wrappedValue : Environment = Environment.empty
}
