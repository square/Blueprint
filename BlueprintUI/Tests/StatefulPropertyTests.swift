//
//  StatefulPropertyTests.swift
//  BlueprintUI-Unit-Tests
//
//  Created by Kyle Van Essen on 6/27/20.
//

import XCTest
@testable import BlueprintUI


class StatefulPropertyTests : XCTestCase
{
    func test_state()
    {
        let test = Test(name: "Kyle")
    }
    
    struct Test {
        @ElementState var name : String = ""
        
        init(name : String) {
            self.name = name
            self.name = name
        }
        
        var body : Element {
            Toggle { isOn in
                self.name = isOn ? "Kyle" : "Not Kyle"
            }
        }
    }


    struct Toggle : UIViewElement {
        
        var onToggle : (Bool) -> ()
        
        init(_ onToggle : @escaping (Bool) -> ()) {
            self.onToggle = onToggle
        }
        
        typealias UIViewType = SwitchView
        
        static func makeUIView() -> UIViewType {
            SwitchView()
        }
        
        func updateUIView(_ view: UIViewType) {
            view.onToggle = self.onToggle
        }
        
        final class SwitchView : UISwitch {
            var onToggle : (Bool) -> () = { _ in }
        }
    }

}
