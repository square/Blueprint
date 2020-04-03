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


public extension Element {
    func updatedElement(with environment : Environment) -> (Element, Environment) {
        guard var updatedElement = self as? EnvironmentElement else {
            return (self, environment)
        }
        
        var updatedEnvironment = environment
        
        updatedElement.editEnvironment(&updatedEnvironment)
        
        updatedElement.environment = updatedEnvironment
        
        return (updatedElement, updatedEnvironment)
    }
}
