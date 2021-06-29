//
//  HTMLParserTests.swift
//  HTMLLabel
//
//  Created by Kyle Van Essen on 12/25/20.
//

import Foundation
import XCTest
@testable import BlueprintUICommonControls


class HTMLParserTests : XCTestCase {
    
    func test_parse() throws {
        
        try self.testcase {
            
            let parsed = try? HTMLParser(
                html: "The <b>quick</b> brown fox jumps over the <i>lazy dog</i>"
            ).parse()
            
            let format = HTML.Format(
                rootAttributes: .init(pointSize: 18.0, weight: .regular),
                tagFormats: [
                    [HTML.Format.TagName(name: "b", synonyms: [])]: HTML.Tag.Format([.font : .init(UIFont.systemFont(ofSize: 20.0, weight: .bold))])
                ]
            )
            
            parsed?.toAttributed(with: format)
        }
        
        try self.testcase("Valid HTML") {
            
            XCTAssertEqual(
                try HTMLParser.parse(html: "<b>Hello, world!</b>"),

                HTML.Tag.root {
                    HTML.Tag(name: "b", children: [
                        .characters("Hello, world!")
                    ])
                }
            )

            XCTAssertEqual(
                try HTMLParser.parse(html: "<b><i>Hello, world!</i></b>"),

                HTML.Tag.root {
                    HTML.Tag(name: "b", children: [
                        .tag(HTML.Tag(name: "i", children: [
                            .characters("Hello, world!")
                        ]))
                    ])
                }
            )

            XCTAssertEqual(
                try HTMLParser.parse(html: "<a href='https://google.com'>Hello, world!</a>"),

                HTML.Tag.root {
                    HTML.Tag(name: "a", attributes: ["href" : "https://google.com"], children: [
                        .characters("Hello, world!")
                    ])
                }
            )
            
            // We should still consider multiple provided root-level tags as valid; since we wrap them in our own root tag.
            
            XCTAssertEqual(
                try HTMLParser.parse(html: "<b>Hello,</b> <i>world!</i>"),
                
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
