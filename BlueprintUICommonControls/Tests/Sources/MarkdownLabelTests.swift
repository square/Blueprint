//
//  MarkdownLabelTests.swift
//  BlueprintUICommonControls-Unit-Tests
//
//  Created by Kyle Van Essen on 6/28/21.
//

@testable import BlueprintUICommonControls
import XCTest


class MarkdownLabelTests : XCTestCase {
    
    
}


class MarkdownLabel_Markdown_Tests : XCTestCase {
    
    func test_parsing_valid() throws {
        
        let raw =
        """
        **Bold** __text__, *italic* _text_, a [link](https://squareup.com). \
        _**Bold** __text__ embedded in italic text._ \
        ***Bold** __text__ embedded in italic text.* \
        """
        
        XCTAssertEqual(
            try Markdown(string: raw),
        )
    }
    
    func test_parsing_invalid() {
        
    }
}
