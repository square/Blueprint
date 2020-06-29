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
        let person = Person(name: "Kyle", isEnabled: false)
        
        let state = LiveElementState(element: person, key: nil, parent: nil)
        
        print("\(state)")
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
                
                row.add(child: CallbackToggle { isOn in
                    self.isEnabled = isOn
                })
                
                row.add(child: BindingToggle(self.$isEnabled))
            }
        }
        
        static let stateKeyPaths: Set<StateKeyPath>? = [
            .init(\Self._name),
            .init(\Self._isEnabled)
        ]
    }

    fileprivate  struct CallbackToggle : UIViewElement {
        
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
    
    fileprivate  struct BindingToggle : UIViewElement {
        
        var isOn : Binding<Bool>
        
        init(_ isOn : Binding<Bool>) {
            self.isOn = isOn
        }
        
        typealias UIViewType = SwitchView
        
        static func makeUIView() -> UIViewType {
            SwitchView()
        }
        
        func updateUIView(_ view: UIViewType) {
            view.onToggle = { isOn in
                self.isOn.wrappedValue = isOn
            }
        }
        
        final class SwitchView : UISwitch {
            var onToggle : (Bool) -> () = { _ in }
        }
    }
}
