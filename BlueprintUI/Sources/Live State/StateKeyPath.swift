//
//  StateKeyPath.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 6/28/20.
//

import Foundation


// https://github.com/Zewo/Reflection/
// https://forums.swift.org/t/state-messing-with-initializer-flow/25276/18


public struct StateKeyPath : Hashable {
        
    init<Root:Element, Value>(_ keyPath : WritableKeyPath<Root, Value>)
    {
        self.anyKeyPath = keyPath
        
        self.getValue = { root in
            (root as! Root)[keyPath: keyPath]
        }
        
        self.setValue = { anyRoot, newValue in
            
            var root = anyRoot as! Root
            
            root[keyPath: keyPath] = newValue as! Value
            
            anyRoot = root
        }
        
        self.makeStorage = { root in
            StatefulStorage((root as! Root)[keyPath: keyPath])
        }
    }

    let getValue : (Element) -> Any
    let setValue : (inout Element, Any) -> ()
    
    let makeStorage : (Element) -> AnyStatefulStorage
    
    private let anyKeyPath : AnyKeyPath
    
    // MARK: Hashable
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.anyKeyPath)
    }
    
    // MARK: Equatable
    
    public static func == (lhs: StateKeyPath, rhs: StateKeyPath) -> Bool {
        lhs.anyKeyPath == rhs.anyKeyPath
    }
}
