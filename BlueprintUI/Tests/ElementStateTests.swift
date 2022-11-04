//
//  ElementStateTests.swift
//
//
//  Created by Kyle Van Essen on 11/3/22.
//

import Foundation
import XCTest
@testable import BlueprintUI


class ElementStateTreeTests: XCTestCase {

    func test_update() throws {

        let tree = ElementStateTree(name: "Testing")
        let element1 = Element1(text: "1")
        let element1b = Element1(text: "1.1")
        let element2 = Element2(text: "2")

        XCTAssertNil(tree.root)

        // Initial update should create a state.

        tree.testingUpdate {
            tree.update(with: element1, in: .empty)
        }

        let state1 = try XCTUnwrap(tree.root)

        XCTAssertEqual((state1.element.value as! Element1).text, "1")

        // Updating with the same element of the same type should keep the same state.

        tree.testingUpdate {
            tree.update(with: element1b, in: .empty)
        }

        let state2 = try XCTUnwrap(tree.root)

        XCTAssertTrue(state1 === state2)

        // Also make sure that we actually update the contained element.

        XCTAssertEqual((state1.element.value as! Element1).text, "1.1")

        // Updating with a new type should tear down the state.

        tree.testingUpdate {
            tree.update(with: element2, in: .empty)
        }

        let state3 = try XCTUnwrap(tree.root)

        XCTAssertFalse(state2 === state3)

        // Updating with nil should tear down the state.

        tree.testingUpdate {
            tree.update(with: nil, in: .empty)
        }

        XCTAssertNil(tree.root)
    }
}


class ElementStateTests: XCTestCase {

    func test_init() {

        testcase("default property values") {
            let state = ElementState(
                parent: nil,
                delegate: nil,
                identifier: .init(elementType: Element1.self, key: nil, count: 1),
                element: Element1(text: "1"),
                depth: 0,
                signpostRef: NSObject(),
                name: ""
            )

            XCTAssertTrue(state.wasVisited)
            XCTAssertFalse(state.wasUpdateEquivalent)
        }

        // TODO: additional codepaths testing.
    }

    func test_elementContent() {
        // TODO:
    }

    func test_measure() {
        // TODO:
    }

    func test_layout() {
        // TODO:
    }

    func test_childState() {
        // TODO:
    }

    func test_prepareForLayout() {
        // TODO:
    }

    func test_finishedLayout() {
        // TODO:
    }

    func test_recursiveForEach() {
        // TODO:
    }
}


fileprivate struct Element1: ProxyElement {

    var text: String

    var elementRepresentation: Element {
        Empty()
    }
}


fileprivate struct Element2: ProxyElement {

    var text: String

    var elementRepresentation: Element {
        Empty()
    }
}


fileprivate struct EquatableElement1: ProxyElement, ComparableElement, Equatable {

    var text: String

    var elementRepresentation: Element {
        Empty()
    }
}


fileprivate struct EquatableElement2: ProxyElement, ComparableElement, Equatable {

    var text: String

    var elementRepresentation: Element {
        Empty()
    }
}


extension ElementStateTree {

    func testingUpdate<Output>(_ block: () -> Output) -> Output {

        root?.prepareForLayout()

        let output = block()

        defer {
            self.root?.finishedLayout()
        }

        return output
    }
}
