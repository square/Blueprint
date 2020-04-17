//
//  Gesture.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 4/16/20.
//

import Foundation


public struct Gesture<GestureType:UIGestureRecognizer> : ProxyElement {
    
    var wrapped : Element
    
    init(gesture : @autoclosure () -> UIGestureRecognizer) {
        fatalError()
    }
    
    // MARK: ProxyElement
    
    public var elementRepresentation: Element {
        self.wrapped
    }
    
    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        ViewDescription(GestureView.self) {
            $0.builder = {
                GestureView(frame: bounds)
            }
        }
    }
}


fileprivate final class GestureView : UIView {
    
}
