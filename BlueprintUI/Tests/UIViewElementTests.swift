//
//  UIViewElementTests.swift
//  BlueprintUI-Unit-Tests
//
//  Created by Kyle Van Essen on 6/8/20.
//

import UIKit
import XCTest
@testable import BlueprintUI


class UIViewElementTests : XCTestCase {
    
    func test_measuring() {

        XCTAssertEqual(
            TestElement(size: CGSize(width: 20.0, height: 30.0)).content.measure(in: .unconstrained),
            CGSize(width: 20.0, height: 30.0)
        )
        
        // Should have allocated one view for measurement.
        XCTAssertEqual(TestElement.makeUIView_count, 1)
        // Should have updated the view once.
        XCTAssertEqual(TestElement.updateUIView_count, 1)
        
        XCTAssertEqual(
            TestElement(size: CGSize(width: 40.0, height: 60.0)).content.measure(in: .unconstrained),
            CGSize(width: 40.0, height: 60.0)
        )
        
        // Should reuse the same view for measurement.
        XCTAssertEqual(TestElement.makeUIView_count, 1)
        // Should have updated the view again.
        XCTAssertEqual(TestElement.updateUIView_count, 2)
    }
}


fileprivate struct TestElement : UIViewElement {
    
    var size : CGSize
    
    typealias UIViewType = TestView
    
    static var makeUIView_count : Int = 0
    
    static func makeUIView() -> TestView {
        Self.makeUIView_count += 1
        
        return TestView()
    }
    
    static var updateUIView_count : Int = 0
    
    func updateUIView(_ view: TestView) {
        Self.updateUIView_count += 1

        view.sizeThatFits = self.size
    }
}


fileprivate final class TestView : UIView {
    
    var sizeThatFits : CGSize = .zero
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        self.sizeThatFits
    }
}
