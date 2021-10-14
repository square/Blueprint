//
//  File.swift
//
//
//  Created by Kyle Bashour on 9/24/21.
//

import XCTest
@testable import BlueprintUI

extension LayoutResultNode {
    func findLayout(of elementType: Element.Type) -> LayoutResultNode? {
        if type(of: element) == elementType {
            return self
        }

        for child in children {
            if let node = child.node.findLayout(of: elementType) {
                return node
            }
        }
        return nil
    }
}
