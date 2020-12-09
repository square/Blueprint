//
//  LayoutWriterTests.swift
//  BlueprintUI-Unit-Tests
//
//  Created by Kyle Van Essen on 12/8/20.
//

import XCTest
@testable import BlueprintUI


class LayoutWriterTests : XCTestCase {
    
    func test_measurement() {
        
        /// `.unionOfChildren`
        
        do {
            let writer = LayoutWriter { context, layout in
                layout.add(with: CGRect(x: 10, y: 20, width: 50, height: 50), child: TestElement())
                layout.add(with: CGRect(x: 20, y: 10, width: 20, height: 100), child: TestElement())
                
                layout.sizing = .unionOfChildren
            }
            
            XCTAssertEqual(writer.content.measure(in: .unconstrained), CGSize(width: 60, height: 110))
        }
        
        
        /// `.fixed`
        
        do {
            let writer = LayoutWriter { context, layout in
                layout.add(with: CGRect(x: 10, y: 20, width: 50, height: 50), child: TestElement())
                
                layout.sizing = .fixed(CGSize(width: 100, height: 100))
            }
            
            XCTAssertEqual(writer.content.measure(in: .unconstrained), CGSize(width: 100, height: 100))
        }

    }
    
    func test_layout() {
        let writer = LayoutWriter { context, layout in
            layout.add(with: CGRect(x: 10, y: 20, width: 50, height: 50), child: TestElement())
            layout.add(with: CGRect(x: 20, y: 10, width: 20, height: 100), child: TestElement())
        }
    
        let layoutResult = writer.content.performLayout(attributes: LayoutAttributes(size: CGSize(width: 100, height: 100)), environment: .empty)
        let innerElement = layoutResult[0]
        
        let nodes = innerElement.node.children.map(\.node)
        
        XCTAssertEqual(nodes.count, 2)
        
        let first = nodes[0]
        let second = nodes[1]

        XCTAssertEqual(first.layoutAttributes.frame, CGRect(x: 10, y: 20, width: 50, height: 50))
        XCTAssertEqual(second.layoutAttributes.frame, CGRect(x: 20, y: 10, width: 20, height: 100))
    }
}


fileprivate struct TestElement : Element {
    
    var content: ElementContent {
        ElementContent { $0.maximum }
    }
    
    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        UIView.describe { _ in }
    }
    
}
