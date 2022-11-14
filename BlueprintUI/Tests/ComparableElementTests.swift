//
//  ComparableElementTests.swift
//
//
//  Created by Kyle Van Essen on 11/3/22.
//

import Foundation
import XCTest
@testable import BlueprintUI


class ComparableElementTests: XCTestCase {

    func test_equatable_conformance() {

        XCTAssertTrue(EquatableElement1(text: "1").isEquivalent(to: EquatableElement1(text: "1")))
        XCTAssertFalse(EquatableElement1(text: "1").isEquivalent(to: EquatableElement1(text: "2")))
    }
}


class AnyComparableElementTests: XCTestCase {

    func test_anyIsEquivalent() {
        XCTAssertTrue(EquatableElement1(text: "1").anyIsEquivalent(to: EquatableElement1(text: "1")))
        XCTAssertFalse(EquatableElement1(text: "1").anyIsEquivalent(to: EquatableElement1(text: "2")))

        XCTAssertFalse(EquatableElement1(text: "1").anyIsEquivalent(to: EquatableElement2(text: "1")))
        XCTAssertFalse(EquatableElement1(text: "1").anyIsEquivalent(to: EquatableElement2(text: "2")))
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
