//
//  DecorateTests.swift
//  BlueprintUI-Unit-Tests
//
//  Created by Kyle Van Essen on 12/10/20.
//

import XCTest
@testable import BlueprintUI


class Decorate_Position_Tests: XCTestCase {

    func test_frame() {

        let contentFrame = CGRect(x: 10, y: 10, width: 50, height: 30)

        // .inset

        let inset = Decorate.Position.inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        XCTAssertEqual(
            inset.frame(with: contentFrame, decoration: DecorationElement(), environment: .empty),
            CGRect(x: 0, y: 0, width: 70, height: 50)
        )

        // .corner

        let topLeft = Decorate.Position.corner(.topLeft, .init(horizontal: 1, vertical: 2))
        XCTAssertEqual(
            topLeft.frame(with: contentFrame, decoration: DecorationElement(), environment: .empty),
            CGRect(x: -4, y: -5.5, width: 10, height: 15)
        )

        let topRight = Decorate.Position.corner(.topRight, .init(horizontal: 1, vertical: 2))
        XCTAssertEqual(
            topRight.frame(with: contentFrame, decoration: DecorationElement(), environment: .empty),
            CGRect(x: 56, y: -5.5, width: 10, height: 15)
        )

        let bottomRight = Decorate.Position.corner(.bottomRight, .init(horizontal: 1, vertical: 2))
        XCTAssertEqual(
            bottomRight.frame(with: contentFrame, decoration: DecorationElement(), environment: .empty),
            CGRect(x: 56, y: 34.5, width: 10, height: 15)
        )

        let bottomLeft = Decorate.Position.corner(.bottomLeft, .init(horizontal: 1, vertical: 2))
        XCTAssertEqual(
            bottomLeft.frame(with: contentFrame, decoration: DecorationElement(), environment: .empty),
            CGRect(x: -4, y: 34.5, width: 10, height: 15)
        )

        // .custom

        let custom = Decorate.Position.custom { context in
            CGRect(x: 10, y: 15, width: 20, height: 30)
        }

        XCTAssertEqual(
            custom.frame(with: contentFrame, decoration: DecorationElement(), environment: .empty),
            CGRect(x: 10, y: 15, width: 20, height: 30)
        )
    }
}


fileprivate struct DecorationElement: Element {

    var content: ElementContent {
        ElementContent { _ in CGSize(width: 10, height: 15) }
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        UIView.describe { _ in }
    }
}
