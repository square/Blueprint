//
//  ViewDiffingBehaviourTests.swift
//  BlueprintUI-Unit-Tests
//
//  Created by Kyle Van Essen on 2/20/20.
//

import Foundation
import XCTest

@testable import BlueprintUI

class ViewDiffingBehaviourTests : XCTestCase
{
    func test_view_instances_do_not_change()
    {
        // Set up initial view and contents.
        
        let view = BlueprintView()
        
        view.element = Row { row in
            row.add(child: A())
            row.add(child: B())
            row.add(child: B())
            row.add(child: C())
            row.add(child: C())
            row.add(key: "1", child: D())
            row.add(key: "2", child: D())
            row.add(key: "1", child: D())
            row.add(key: "2", child: D())
        }
        
        view.layoutIfNeeded()
        
        // Get first reference to native views. Verify they are in the correct
        // order and of the correct type.
        
        var elementViews = view.rootNativeElementViews
        
        XCTAssertEqual(elementViews.count, 9)
        
        let elementA_layout1 = elementViews[0]
        let elementB1_layout1 = elementViews[1]
        let elementB2_layout1 = elementViews[2]
        let elementC1_layout1 = elementViews[3]
        let elementC2_layout1 = elementViews[4]
        let elementD1_key1_layout1 = elementViews[5]
        let elementD2_key2_layout1 = elementViews[6]
        let elementD3_key1_layout1 = elementViews[7]
        let elementD4_key2_layout1 = elementViews[8]
        
        XCTAssertTrue(type(of: elementA_layout1) == A.View.self)
        XCTAssertTrue(type(of: elementB1_layout1) == B.View.self)
        XCTAssertTrue(type(of: elementB2_layout1) == B.View.self)
        XCTAssertTrue(type(of: elementC1_layout1) == C.View.self)
        XCTAssertTrue(type(of: elementC2_layout1) == C.View.self)
        XCTAssertTrue(type(of: elementD1_key1_layout1) == D.View.self)
        XCTAssertTrue(type(of: elementD2_key2_layout1) == D.View.self)
        XCTAssertTrue(type(of: elementD3_key1_layout1) == D.View.self)
        XCTAssertTrue(type(of: elementD4_key2_layout1) == D.View.self)
        
        
        // Update the element, which should remove elementA and elementB2.
        // The views for B1, C1, and C2 should remain the same, because
        // their identifiers are consistent across layout passes.
        
        view.element = Row { row in
            row.add(child: B())
            row.add(child: C())
            row.add(child: C())
            row.add(key: "1", child: D())
            row.add(key: "2", child: D())
        }
        
        view.layoutIfNeeded()
        
        elementViews = view.rootNativeElementViews
        
        XCTAssertEqual(elementViews.count, 5)
        
        let elementB1_layout2 = elementViews[0]
        let elementC1_layout2 = elementViews[1]
        let elementC2_layout2 = elementViews[2]
        let elementD1_key1_layout2 = elementViews[3]
        let elementD2_key2_layout2 = elementViews[4]
        
        XCTAssertTrue(type(of: elementB1_layout2) == B.View.self)
        XCTAssertTrue(type(of: elementC1_layout2) == C.View.self)
        XCTAssertTrue(type(of: elementC2_layout2) == C.View.self)
        XCTAssertTrue(type(of: elementD1_key1_layout1) == D.View.self)
        XCTAssertTrue(type(of: elementD2_key2_layout1) == D.View.self)
        
        XCTAssertEqual(elementB1_layout1, elementB1_layout2)
        XCTAssertEqual(elementC1_layout1, elementC1_layout2)
        XCTAssertEqual(elementC2_layout1, elementC2_layout2)
        XCTAssertEqual(elementD1_key1_layout1, elementD1_key1_layout2)
        XCTAssertEqual(elementD2_key2_layout1, elementD2_key2_layout2)
    }
}


fileprivate struct A : Element
{
    var content: ElementContent {
        return ElementContent(intrinsicSize: CGSize(width: 10, height: 10))
    }
    
    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return View.describe { _ in}
    }
    
    final class View : UIView {}
}


fileprivate struct B : Element
{
    var content: ElementContent {
        return ElementContent(intrinsicSize: CGSize(width: 10, height: 10))
    }
    
    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        
        return View.describe { _ in}
    }
    
    final class View : UIView {}
}


fileprivate struct C : Element
{
    var content: ElementContent {
        return ElementContent(intrinsicSize: CGSize(width: 10, height: 10))
    }
    
    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        
        return View.describe { _ in}
    }
    
    final class View : UIView {}
}


fileprivate struct D : Element
{
    var content: ElementContent {
        return ElementContent(intrinsicSize: CGSize(width: 10, height: 10))
    }
    
    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        
        return View.describe { _ in}
    }
    
    final class View : UIView {}
}
