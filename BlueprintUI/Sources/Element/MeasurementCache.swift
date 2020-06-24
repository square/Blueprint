//
//  MeasurementCache.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 6/23/20.
//

import Foundation

///
/// A cache used to speed up measurement and layout, when the measurement of an `Element` can
/// be easily cached by storing a value representing the content of an element, eg for a Label.
/// 
final class MeasurementCache
{
    private var measurements : [Key:CGSize] = [:]
    
    func measurement(
        with key : MeasurementCachingKey?,
        in sizeConstraint : SizeConstraint,
        measure : () -> CGSize
    ) -> CGSize
    {
        guard let key = key else {
            return measure()
        }
        
        let innerKey = Key(
            key: key,
            sizeConstraint: sizeConstraint
        )
        
        if let existing = self.measurements[innerKey] {
            return existing
        }
        
        let size = measure()
        
        self.measurements[innerKey] = size
        
        return size
    }
    
    private struct Key : Hashable
    {
        let key : MeasurementCachingKey
        let sizeConstraint : SizeConstraint
        
        let hash : Int
        
        init(key : MeasurementCachingKey, sizeConstraint : SizeConstraint)
        {
            self.key = key
            self.sizeConstraint = sizeConstraint
            
            var hasher = Hasher()
            hasher.combine(self.key)
            hasher.combine(self.sizeConstraint)
            self.hash = hasher.finalize()
        }
        
        func hash(into hasher: inout Hasher) {
            // We pre-compute the hash above to avoid potentially expensive work here.
            // Computing the hash repeatedly for `input` may be slow (especially for strings).
            hasher.combine(self.hash)
        }
    }
}
