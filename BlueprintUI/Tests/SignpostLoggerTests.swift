//
//  SignpostLoggerTests.swift
//  BlueprintUI-Unit-Tests
//
//  Created by Kyle Van Essen on 6/30/20.
//

import XCTest
@testable import BlueprintUI


class SignpostLoggerTests : XCTestCase {
    
    func test_isLoggingEnabled_true_in_debug()
    {
        /// Test to validate that no one has accidentally committed disabling `isLoggingEnabled` in `DEBUG`.
        
        #if DEBUG
        XCTAssertEqual(true, SignpostLogger.isLoggingEnabled)
        #endif
    }
}
