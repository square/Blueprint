//
//  StatefulViewController.swift
//  SampleApp
//
//  Created by Kyle Van Essen on 6/30/21.
//  Copyright © 2021 Square. All rights reserved.
//

import UIKit
import BlueprintUI
import BlueprintUICommonControls


final class StatefulViewController : UIViewController
{
    override func loadView() {
        let blueprintView = BlueprintView(element: self.contents)

        self.view = blueprintView

        self.view.backgroundColor = .init(white: 0.9, alpha: 1.0)
    }

    var contents : Element {
        Column { col in
            col.horizontalAlignment = .fill
            
            for _ in 1...10 {
                col.addFixed(child: ToggleRow())
            }
        }
        .scrollable {
            $0.alwaysBounceVertical = true
        }
    }
}


struct ToggleRow : ProxyElement, StatefulElement {
    
    @ElementState var isOn : Bool = false
    
    var elementRepresentation: Element {
        Row { row in
            row.horizontalUnderflow = .growUniformly
            row.verticalAlignment = .center
            
            row.addFixed(child: Label(text: "This is a row") {
                $0.font = .systemFont(ofSize: 18.0, weight: .medium)
            })
            
            row.addFlexible(child: Spacer.horizontal)
            
            row.addFixed(child: Toggle(isOn: $isOn))
        }
        .inset(uniform: 20.0)
    }
}


struct Toggle : UIViewElement {

    typealias UIViewType = View
    
    var isOn : ElementState<Bool>.Binding
    
    static func makeUIView() -> View {
        View()
    }
    
    func updateUIView(_ view: View, with context: UIViewElementContext) {
        view.onBinding = self.isOn
    }
    
    final class View : UISwitch {
        
        var onBinding : ElementState<Bool>.Binding? = nil
        
        init() {
            super.init(frame: .zero)
            
            self.addTarget(self, action: #selector(toggled), for: .valueChanged)
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        @objc private func toggled() {
            onBinding?.value.toggle()
        }
    }
}
