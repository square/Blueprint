//
//  ScrollViewTests.swift
//  BlueprintUICommonControls-Unit-Tests
//
//  Created by Kyle Van Essen on 2/26/20.
//

import Foundation
import XCTest

import BlueprintUI

@testable import BlueprintUICommonControls


class ScrollViewTests : XCTestCase {
    
    func test_contentInset() {
        
        let view = BlueprintView()
    }
    
    func test_finalContentInset()
    {
        // No inset
        
        XCTAssertEqual(
            UIEdgeInsets.zero,
            
            ScrollView.calculateContentInset(
                scrollViewInsets: .zero,
                safeAreaInsets: UIEdgeInsets(top: 10.0, left: 11.0, bottom: 12.0, right: 13.0),
                keyboardBottomInset: .zero,
                refreshControlState: .disabled,
                refreshControlBounds: CGRect(origin: .zero, size: CGSize(width: 25.0, height: 25.0))
            )
        )
        
        // Keyboard Inset
        
        XCTAssertEqual(
            UIEdgeInsets(top: 10.0, left: 11.0, bottom: 50.0, right: 13.0),
            
            ScrollView.calculateContentInset(
                scrollViewInsets: UIEdgeInsets(top: 10.0, left: 11.0, bottom: 12.0, right: 13.0),
                safeAreaInsets: UIEdgeInsets(top: 10.0, left: 11.0, bottom: 12.0, right: 13.0),
                keyboardBottomInset: 50.0,
                refreshControlState: .disabled,
                refreshControlBounds: CGRect(origin: .zero, size: CGSize(width: 25.0, height: 25.0))
            )
        )
        
        // Keyboard Inset and refreshing state
        
        XCTAssertEqual(
            UIEdgeInsets(top: 35.0, left: 11.0, bottom:50.0, right: 13.0),
            
            ScrollView.calculateContentInset(
                scrollViewInsets: UIEdgeInsets(top: 10.0, left: 11.0, bottom: 12.0, right: 13.0),
                safeAreaInsets: UIEdgeInsets(top: 10.0, left: 11.0, bottom: 12.0, right: 13.0),
                keyboardBottomInset: 50.0,
                refreshControlState: .refreshing,
                refreshControlBounds: CGRect(origin: .zero, size: CGSize(width: 25.0, height: 25.0))
            )
        )
    }
}
