//
//  ParserTests.swift
//  HTMLLabel
//
//  Created by Kyle Van Essen on 12/25/20.
//

import Foundation
import XCTest
@testable import BlueprintUICommonControls


class ParserTests : XCTestCase {
    
    func test_parse() {
        
        try? self.testcase("Valid HTML") {
            
            XCTAssertEqual(
                try Parser.parse(html: "<b>Hello, world!</b>"),

                HTML.Tag.root {
                    HTML.Tag(name: "b", children: [
                        .characters("Hello, world!")
                    ])
                }
            )

            XCTAssertEqual(
                try Parser.parse(html: "<b><i>Hello, world!</i></b>"),

                HTML.Tag.root {
                    HTML.Tag(name: "b", children: [
                        .tag(HTML.Tag(name: "i", children: [
                            .characters("Hello, world!")
                        ]))
                    ])
                }
            )

            XCTAssertEqual(
                try Parser.parse(html: "<a href='https://google.com'>Hello, world!</a>"),

                HTML.Tag.root {
                    HTML.Tag(name: "a", attributes: ["href" : "https://google.com"], children: [
                        .characters("Hello, world!")
                    ])
                }
            )
            
            // We should still consider multiple provided root-level tags as valid; since we wrap them in our own root tag.
            
            XCTAssertEqual(
                try Parser.parse(html: "<b>Hello,</b> <i>world!</i>"),
                
                HTML.Tag.root {
                    [
                        .tag(HTML.Tag(name: "b", children: [
                            .characters("Hello,")
                        ])),
                        
                        .characters(" "),
                        
                        .tag(HTML.Tag(name: "i", children: [
                            .characters("world!")
                        ]))
                    ]
                }
            )
        }
        
        
//        try? self.testcase("Invalid HTML") {
//            XCTAssertEqual(
//                try Parser.parse(html: "<b>Hello,</b> <i>world!</i>"),
//
//                nil
//            )
//        }
    }
}
