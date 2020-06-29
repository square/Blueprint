//
//  ElementStateController.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 6/28/20.
//

import Foundation


final class ElementStateController {
    
    private var states : [ElementState] = []
    
    var stateDidChange : () -> ()
    
    init?(with element : Element) {
        guard let keyPaths = element.stateKeyPaths else {
            return nil
        }
        
        self.states = keyPaths.map { keyPath in
            ElementState(keyPath: keyPath, element: element)
        }
        
        self.stateDidChange = { }
        
        self.states.forEach { state in
            state.storage.valueDidChange = { [weak self] in
                self?.elementStateDidChange()
            }
        }
    }
    
    func get(from element : Element)
    {
        self.states.forEach { state in
            state.storage.anyValue = state.keyPath.getValue(element)
        }
    }
    
    func setting(on element : Element) -> Element
    {
        var updated = element
        
        self.states.forEach { state in
            state.keyPath.setStorage(&updated, state.storage)
        }
        
        return updated
    }
    
    private func elementStateDidChange()
    {
        self.stateDidChange()
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
