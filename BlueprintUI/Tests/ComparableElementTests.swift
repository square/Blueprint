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

        let context = ComparableElementContext(environment: .empty)

        XCTAssertTrue(EquatableElement1(text: "1").isEquivalent(to: EquatableElement1(text: "1"), in: context))
        XCTAssertFalse(EquatableElement1(text: "1").isEquivalent(to: EquatableElement1(text: "2"), in: context))
    }
}


class AnyComparableElementTests: XCTestCase {

    func test_anyIsEquivalent() {
        let context = ComparableElementContext(environment: .empty)

        XCTAssertTrue(EquatableElement1(text: "1").anyIsEquivalent(to: EquatableElement1(text: "1"), in: context))
        XCTAssertFalse(EquatableElement1(text: "1").anyIsEquivalent(to: EquatableElement1(text: "2"), in: context))

        XCTAssertFalse(EquatableElement1(text: "1").anyIsEquivalent(to: EquatableElement2(text: "1"), in: context))
        XCTAssertFalse(EquatableElement1(text: "1").anyIsEquivalent(to: EquatableElement2(text: "2"), in: context))
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
