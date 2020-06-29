//
//  StatefulElementPropertyValidator.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 6/28/20.
//

import Foundation


internal final class StatefulElementPropertyValidator {
    
    private static var validatedTypes : Set<ObjectIdentifier> = []
    
    static func validate(typeOf element : Element)
    {
        let elementType = type(of: element)
        
        let identifier = ObjectIdentifier(elementType)
        
        guard self.validatedTypes.contains(identifier) == false else {
            return
        }
        
        self.validatedTypes.insert(identifier)
        
        guard let states = elementType.stateKeyPaths else {
            return
        }
        
        let mirror = Mirror(reflecting: element)
        
        let properties : [String] = mirror.children.compactMap { child in
            guard let name = child.label, child.value is StatefulElementProperty else {
                return nil
            }
            
            return name
        }
        
        precondition(states.count == properties.count, "Not all StatefulElementProperty are accounted for in the `states` property. Please add them.")
    }
}
