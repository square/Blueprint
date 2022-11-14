//
//  XCTestCaseAdditions.swift
//
//
//  Created by Kyle Van Essen on 11/3/22.
//

import Foundation
import XCTest

extension XCTestCase {

    /// Provides scoping within a single `func test...()` method, eg
    /// if you want to test multiple cases / permutations with a label.
    public func testcase(
        _ name: String = "",
        _ block: () throws -> Void
    ) rethrows {
        try block()
    }
}
