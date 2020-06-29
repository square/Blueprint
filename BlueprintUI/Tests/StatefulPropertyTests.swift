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
        let test = Person(name: "Kyle", isEnabled: false)
    }
    
    fileprivate struct Person : ProxyElement {
        @Stateful var name : String
        @Stateful var isEnabled : Bool
        
        init(name : String, isEnabled : Bool) {
            _name = .init(name)
            _isEnabled = .init(isEnabled)
        }
        
        var elementRepresentation: Element {
            Row { row in
                row.verticalAlignment = .center
                row.minimumHorizontalSpacing = 20.0
                
                row.add(child: Toggle { isOn in
                    self.isEnabled = isOn
                })
            }
        }
        
        static var states: [StateKeyPath] {
            [
                .init(\Self.name),
                .init(\Self.isEnabled)
            ]
        }
        
    }

    fileprivate  struct Toggle : UIViewElement {
        
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
