//
//  ElementAdditions.swift
//  BlueprintUIDebugging
//
//  Created by Kyle Van Essen on 4/24/20.
//

import BlueprintUI


extension Element {
    
    func recursiveElementList() -> [RecursedElement] {
        var list = [RecursedElement]()
        
        self.appendTo(recursiveElementList: &list, depth: 0)
        
        return list
    }
    
    private func appendTo(recursiveElementList list : inout [RecursedElement], depth : Int) {
        list.append(RecursedElement(element: self, depth: depth))
        
        self.content.childElements.forEach {
            $0.appendTo(recursiveElementList: &list, depth: depth + 1)
        }
    }
}


struct RecursedElement {
    var element : Element
    var depth : Int
}
