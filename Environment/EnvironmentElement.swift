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


public struct EnvironmentEditor : ProxyElement, EnvironmentElement {
    
    public var environment: Environment = .empty
    
    public var wrapped : Element
    public var edit : (inout Environment) -> ()
    
    public var elementRepresentation: Element {
        self.wrapped
    }
    
    public init(wrapping : Element, _ edit : @escaping (inout Environment) -> ()) {
        self.wrapped = wrapping
        self.edit = edit
    }
    
    public func editEnvironment(_ environment: inout Environment) {
        self.edit(&environment)
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
