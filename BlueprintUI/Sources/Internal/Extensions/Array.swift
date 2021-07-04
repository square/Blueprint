//
//  Array.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 7/2/21.
//

import Foundation


extension Array {
    
    /// A `map` implementation that also passes the `index` of each element in the original array.
    ///
    /// This method is more performant than calling `array.enumerated().map(...)` by up
    /// to 25% for large collections, so prefer it when needing an indexed `map` in areas where performance is critical.
    @inline(__always) func indexedMap<Mapped>(_ map : (Int, Element) -> Mapped) -> [Mapped] {
        
        let count = self.count
        
        var mapped = [Mapped]()
        mapped.reserveCapacity(count)
        
        for index in 0..<count {
            mapped.append(map(index, self[index]))
        }
        
        return mapped
    }
    
    /// A `forEach` implementation that also passes the `index` of each element in the original array.
    ///
    /// This method is more performant than calling `array.enumerated().forEac(...)` by up
    /// to 25% for large collections, so prefer it when needing an indexed `forEach` in areas where performance is critical.
    @inline(__always) func indexedForEach(_ each : (Int, Element) -> Void) {
        
        let count = self.count

        for index in 0..<count {
            each(index, self[index])
        }
    }
}
