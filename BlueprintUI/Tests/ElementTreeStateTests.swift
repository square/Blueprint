//
//  ElementTreeStateTests.swift
//  BlueprintUI-Unit-Tests
//
//  Created by Kyle Van Essen on 6/23/20.
//

import UIKit
import XCTest
@testable import BlueprintUI


class ElementTreeStateTests : XCTestCase
{
    
}


class ElementTreeState_Element_Tests : XCTestCase
{
    func test_isSameTypeAs()
    {
        let first = TestElement1(text: "one")
        let second = TestElement2(text: "two")
        
        XCTAssertEqual(first.isSameType(as: first), true)
        XCTAssertEqual(first.isSameType(as: second), false)
    }
}


fileprivate struct TestElement1 : UIViewElement
{
    var text : String
    
    typealias UIViewType = UILabel
    
    static func makeUIView() -> UILabel {
        UILabel()
    }
    
    func updateUIView(_ view: UILabel) {
        view.text = text
    }
}


fileprivate struct TestElement2 : UIViewElement
{
    var text : String
    
    typealias UIViewType = UILabel
    
    static func makeUIView() -> UILabel {
        UILabel()
    }
    
    func updateUIView(_ view: UILabel) {
        view.text = text
    }
}
