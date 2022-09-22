//
//  DecorateTests.swift
//  BlueprintUI-Unit-Tests
//
//  Created by Kyle Van Essen on 12/10/20.
//

import XCTest
@testable import BlueprintUI


class Decorate_Position_Tests: XCTestCase {

    func test_root_size() {

        let decorate = Decorate(
            layering: .above,
            position: .corner(.topLeft, .zero),
            wrapping: BaseElement(),
            decoration: DecorationElement()
        )

        let layout = decorate
            .layout(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
            .children[0].node
            .children[0].node
            .children[0].node
            .children[0].node
            .children[0].node
            .children
            .map { $0.node }

        XCTAssertEqual(layout.count, 2)

        XCTAssertEqual(layout[0].layoutAttributes.bounds.size, CGSize(width: 100, height: 100))
        XCTAssertEqual(layout[1].layoutAttributes.bounds.size, CGSize(width: 10, height: 15))
    }

    func test_frame() {

        let contentSize = CGSize(width: 50, height: 30)

        // .inset

        let inset = Decorate.Position.inset(UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
        XCTAssertEqual(
            inset.frame(with: contentSize, decoration: DecorationElement(), environment: .empty),
            CGRect(x: -10, y: -10, width: 70, height: 50)
        )

        // .aligned

        let alignedBottom = Decorate.Position.aligned(to: .bottom)
        XCTAssertEqual(
            alignedBottom.frame(with: contentSize, decoration: DecorationElement(), environment: .empty),
            CGRect(x: 20, y: 15, width: 10, height: 15)
        )

        let alignedBottomWithGuides = Decorate.Position.aligned(
            to: .bottom,
            horizontalGuide: { d in 3 },
            verticalGuide: { d in 4 }
        )
        XCTAssertEqual(
            alignedBottomWithGuides.frame(with: contentSize, decoration: DecorationElement(), environment: .empty),
            CGRect(x: 22, y: 26, width: 10, height: 15)
        )

        // .corner

        let topLeft = Decorate.Position.corner(.topLeft, .init(horizontal: 1, vertical: 2))
        XCTAssertEqual(
            topLeft.frame(with: contentSize, decoration: DecorationElement(), environment: .empty),
            CGRect(x: -4, y: -5.5, width: 10, height: 15)
        )

        let topRight = Decorate.Position.corner(.topRight, .init(horizontal: 1, vertical: 2))
        XCTAssertEqual(
            topRight.frame(with: contentSize, decoration: DecorationElement(), environment: .empty),
            CGRect(x: 46, y: -5.5, width: 10, height: 15)
        )

        let bottomRight = Decorate.Position.corner(.bottomRight, .init(horizontal: 1, vertical: 2))
        XCTAssertEqual(
            bottomRight.frame(with: contentSize, decoration: DecorationElement(), environment: .empty),
            CGRect(x: 46, y: 24.5, width: 10, height: 15)
        )

        let bottomLeft = Decorate.Position.corner(.bottomLeft, .init(horizontal: 1, vertical: 2))
        XCTAssertEqual(
            bottomLeft.frame(with: contentSize, decoration: DecorationElement(), environment: .empty),
            CGRect(x: -4, y: 24.5, width: 10, height: 15)
        )

        // .custom

        let custom = Decorate.Position.custom { context in
            CGRect(x: 10, y: 15, width: 20, height: 30)
        }

        XCTAssertEqual(
            custom.frame(with: contentSize, decoration: DecorationElement(), environment: .empty),
            CGRect(x: 10, y: 15, width: 20, height: 30)
        )
    }
}

fileprivate struct BaseElement: Element {

    var content: ElementContent {
        ElementContent { _ in CGSize(width: 60, height: 70) }
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        UIView.describe { _ in }
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
