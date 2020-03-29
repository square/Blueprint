//
//  EnvironmentTests.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 3/28/20.
//

import Foundation
import XCTest
@testable import BlueprintUI


class EnvironmentTests : XCTestCase {
    
    func test() {
        let a = A(child: B(child: C()))
        
        a.layout(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)), environment: Environment {
            $0[SafeAreaInsetsKey.self] = UIEdgeInsets(top: 10, left: 11, bottom: 12, right: 13)
        })
    }
    
    struct SafeAreaInsetsKey : EnvironmentKey {
        typealias Value = UIEdgeInsets
        
        static var defaultValue: UIEdgeInsets = .zero
    }
    
    struct A : Element, EnvironmentElement {
        
        struct Key : EnvironmentKey {
            typealias Value = String
            
            static var defaultValue: String {
                return "A Default"
            }
        }
        
        var environment : Environment = .empty
        
        var child : B
        
        var content: ElementContent {
            ElementContent(child: self.child)
        }
        
        func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
            UIView.describe { _ in }
        }
        
        func editEnvironment(_ environment: inout Environment) {
            environment[Key.self] = "A Key"
        }
    }
    
    struct B : Element, EnvironmentElement {
        
        struct Key : EnvironmentKey {
            typealias Value = String
            
            static var defaultValue: String {
                return "B Default"
            }
        }
        
        var environment : Environment = .empty

        var child : C
        
        var content: ElementContent {
            ElementContent(child: self.child)
        }
        
        func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
            UIView.describe { _ in }
        }
        
        func editEnvironment(_ environment: inout Environment) {
            environment[Key.self] = "B Key"
        }
    }
    
    struct C : Element, EnvironmentElement {
        var environment : Environment = .empty

        var content: ElementContent {
            ElementContent(intrinsicSize: CGSize(width: 10.0, height: 10.0))
        }
        
        func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
            UIView.describe { _ in }
        }
        
        func editEnvironment(_ environment: inout Environment) {
            print("Edit C: \(environment)")
        }
    }
}
