//
//  KeyedTests.swift
//  BlueprintUI-Unit-Tests
//
//  Created by Kyle Van Essen on 4/5/21.
//

import XCTest
import BlueprintUI


class KeyedTests : XCTestCase {
    
    func test_measure() {
        let element = TestElement().keyed("the-key")
        
        XCTAssertEqual(
            element.content.measure(in: .unconstrained),
            CGSize(width: 100, height: 110)
        )
    }
    
    func test_swaps_view() {
        
        let view = BlueprintView()
        view.frame.size = CGSize(width: 200, height: 200)
        
        view.element = TestElement().keyed("1")
        view.layoutIfNeeded()
        
        let view1 = view.subviews[0].subviews[0] as! TestElement.View
        
        view.element = TestElement().keyed("1")
        view.layoutIfNeeded()
        
        let view2 = view.subviews[0].subviews[0] as! TestElement.View
        
        // If we don't change the key, keep the same view.
        
        XCTAssertEqual(view1, view2)
        
        view.element = TestElement().keyed("2")
        view.layoutIfNeeded()
        
        let view3 = view.subviews[0].subviews[0] as! TestElement.View
        
        // Changing the key, even with the same element type, should change the view.
        
        XCTAssertNotEqual(view1, view3)
    }
}


fileprivate struct TestElement : Element {
    
    var content: ElementContent {
        ElementContent(intrinsicSize: CGSize(width: 100, height: 110))
    }
    
    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        View.describe { _ in }
    }
    
    final class View : UIView {}
}
