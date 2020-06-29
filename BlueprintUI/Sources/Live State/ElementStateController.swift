//
//  ElementStateController.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 6/28/20.
//

import Foundation


final class ElementStateController {
    
    private var states : [ElementState] = []
    
    init?(with element : Element) {
        guard let keyPaths = element.stateKeyPaths else {
            return nil
        }
        
        self.states = keyPaths.map { keyPath in
            ElementState(keyPath: keyPath, element: element)
        }
    }
    
    func get(from element : Element)
    {
        self.states.forEach { state in
            state.storage.anyValue = state.keyPath.getValue(element)
        }
    }
    
    func set(on element : inout Element)
    {
        self.states.forEach { state in
            state.keyPath.setValue(&element, state.storage.anyValue)
        }
    }
    
    final class ElementState {
        
        let keyPath : StateKeyPath
        let storage : AnyStatefulStorage
        
        init(keyPath : StateKeyPath, element : Element) {
            self.keyPath = keyPath
            self.storage = self.keyPath.makeStorage(element)
        }
    }
}
