//
//  AdaptedEnvironmentTests.swift
//  BlueprintUI-Unit-Tests
//
//  Created by Kyle Van Essen on 6/28/21.
//

@testable import BlueprintUI
import XCTest


class AdaptedEnvironmentTests : XCTestCase {
    
    func test_adapting() {
        let view = BlueprintView()
        
        var environment : Environment? = nil
        
        view.element = TestElement { environment = $0 }
        .adaptedEnvironment(key: TestingKey1.self, value: "adapted1")
        
        view.layoutIfNeeded()
        
        XCTAssertEqual(environment?[TestingKey1.self], "adapted1")
    }
    
    func test_wrapping_multiple() {
        let view = BlueprintView()
        
        var environment : Environment? = nil
        
        let element = TestElement { environment = $0 }
        .adaptedEnvironment(key: TestingKey1.self, value: "adapted1.1")
        .adaptedEnvironment(key: TestingKey1.self, value: "adapted1.2")
        .adaptedEnvironment(key: TestingKey2.self, value: "adapted2.1")
        .adaptedEnvironment(key: TestingKey1.self, value: "adapted1.3")
        .adaptedEnvironment(key: TestingKey2.self, value: "adapted2.2")
        
        view.element = element
        
        view.layoutIfNeeded()
        
        // The inner-most change; the one closest to the element; should be the value we get.
        XCTAssertEqual(environment?[TestingKey1.self], "adapted1.1")
        XCTAssertEqual(environment?[TestingKey2.self], "adapted2.1")
        
        // Ensure we collapsed the AdaptedEnvironments down to one level of wrapping.
        XCTAssertTrue((element as? AdaptedEnvironment)?.wrapped is TestElement)
    }
}


fileprivate enum TestingKey1 : EnvironmentKey {
    static let defaultValue: String? = nil
}


fileprivate enum TestingKey2 : EnvironmentKey {
    static let defaultValue: String? = nil
}


fileprivate struct TestElement : ProxyElement {
    
    var read : (Environment) -> ()
    
    var elementRepresentation: Element {
        EnvironmentReader { env in
            read(env)
            
            return Empty()
        }
    }
}
