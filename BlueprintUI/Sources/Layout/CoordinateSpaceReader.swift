//
//  CoordinateSpaceReader.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 4/5/21.
//

import Foundation


public struct CoordinateSpaceReader : Element {
    
    public var wrapping : Element
    
    public var onCoordinateSpaceChanged : (UICoordinateSpace) -> ()
    
    init(_ wrapping : Element, onCoordinateSpaceChanged : @escaping (UICoordinateSpace) -> ()) {
        self.wrapping = wrapping
        self.onCoordinateSpaceChanged = onCoordinateSpaceChanged
    }
    
    public var content: ElementContent {
        ElementContent(child: self.wrapping)
    }
    
    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        PassthroughView.describe { config in
            config.onCoordinateSpaceChanged = self.onCoordinateSpaceChanged
        }
    }
}
