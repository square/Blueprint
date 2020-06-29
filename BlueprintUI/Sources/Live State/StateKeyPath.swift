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
        
    init<Root:Element, Value:StatefulElementProperty>(_ keyPath : WritableKeyPath<Root, Value>)
    {
        self.anyKeyPath = keyPath
        
        self.getValue = { root in
            (root as! Root)[keyPath: keyPath]
        }
        
        self.setStorage = { anyRoot, storage in
            var root = anyRoot as! Root
            
            root[keyPath: keyPath].setLiveStorage(storage)
            
            anyRoot = root
        }
        
        self.makeStorage = { root in
            StatefulStorage((root as! Root)[keyPath: keyPath].wrappedValue)
        }
    }

    let getValue : (Element) -> Any
    
    let setStorage : (inout Element, AnyStatefulStorage) -> ()
    
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
