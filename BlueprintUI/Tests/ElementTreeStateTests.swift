//
//  ElementTreeStateTests.swift
//  BlueprintUI-Unit-Tests
//
//  Created by Kyle Van Essen on 6/23/20.
//

import UIKit
import XCTest
@testable import BlueprintUI





fileprivate struct TestElement1 : UIViewElement
{
    var text : String
    
    typealias UIViewType = UILabel
    
    static func makeUIView() -> UILabel {
        UILabel()
    }
    
    func updateUIView(_ view: UILabel) {
        view.text = text
    }
}


fileprivate struct TestElement2 : UIViewElement
{
    var text : String
    
    typealias UIViewType = UILabel
    
    static func makeUIView() -> UILabel {
        UILabel()
    }
    
    func updateUIView(_ view: UILabel) {
        view.text = text
    }
}
