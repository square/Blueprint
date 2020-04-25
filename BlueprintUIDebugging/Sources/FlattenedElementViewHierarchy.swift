//
//  FlattenedElementViewHierarchy.swift
//  BlueprintUIDebugging
//
//  Created by Kyle Van Essen on 4/24/20.
//

import UIKit
import BlueprintUI
import BlueprintUICommonControls


struct FlattenedElementViewHierarchy {
    let element : Element
    let flatHierarchySnapshot : [ViewSnapshot]
    let size : CGSize
    
    init(element : Element, sizeConstraint : SizeConstraint) {
        self.element = element
        
        self.size = self.element.content.measure(in: sizeConstraint)
        
        let view = BlueprintView(frame: CGRect(origin: .zero, size: self.size))
        view.debugging.showElementFrames = .all
        view.debugging.isIn3DPreview = true
        
        view.element = self.element
        view.layoutIfNeeded()
        
        var snapshot = [ViewSnapshot]()
        
        view.buildFlatHierarchySnapshot(in: &snapshot, rootView: view, depth: 0)
        
        self.flatHierarchySnapshot = snapshot
    }
    
    struct ViewSnapshot {
        var element : Element
        var view : UIView
        var frame : CGRect
        var hierarchyDepth : Int
    }
}


fileprivate extension UIView {
            
    func buildFlatHierarchySnapshot(in list : inout [FlattenedElementViewHierarchy.ViewSnapshot], rootView : UIView, depth : Int) {
        
        if let self = self as? DebuggingView {
            let snapshot = FlattenedElementViewHierarchy.ViewSnapshot(
                element: self.elementInfo.element,
                view: self,
                frame: self.convert(self.bounds, to: rootView),
                hierarchyDepth: depth
            )
            
            list.append(snapshot)
        }
        
        for view in self.subviews {
            view.buildFlatHierarchySnapshot(in: &list, rootView: rootView, depth: depth + 1)
        }
        
        if self is DebuggingView {
            self.removeFromSuperview()
        }
    }
}
