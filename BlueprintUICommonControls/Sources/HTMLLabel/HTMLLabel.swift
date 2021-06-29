//
//  HTMLLabel.swift
//  BlueprintUICommonControls
//
//  Created by Kyle Van Essen on 6/28/21.
//

import BlueprintUI


public struct HTMLLabel : UIViewElement {
    
    public var text : String
    
    public static func makeUIView() -> UILabel {
        UILabel()
    }
    
    public func updateUIView(_ view: UILabel, with context: UIViewElementContext) {
        view.set(html: self.text, with: <#T##Any#>)
    }
}
