//
//  PointerInteractionViewController.swift
//  SampleApp
//
//  Created by Kyle Van Essen on 6/26/20.
//  Copyright © 2020 Square. All rights reserved.
//

import UIKit
import BlueprintUI
import BlueprintUICommonControls


#if swift(>=5.2)


@available(iOS 13.4, *)
final class PointerInteractionViewController : UIViewController
{
    override func loadView() {
        let blueprintView = BlueprintView(element: self.content)
        
        self.view = blueprintView
    }
    
    var content : Element {
        Column { col in
            col.horizontalAlignment = .center
            col.minimumVerticalSpacing = 20.0
            
            col.add(
                child: InteractiveElement(
                    content: Label(text: "I Am A Button") {
                        $0.font = .systemFont(ofSize: 18.0, weight: .semibold)
                        $0.color = .white
                    }
                    .inset(uniform: 20.0)
                    .box(
                        background: .systemBlue,
                        corners: .rounded(radius: 6.0),
                        shadow: .simple(radius: 6.0, opacity: 0.3, offset: CGSize(width: 0.0, height: 2.0), color: .black)
                    )
                    .pointerInteraction()
                )
            )
            
            col.add(
                child: InteractiveElement(
                    content: Label(text: "A Label (Box)") {
                        $0.color = .darkGray
                        $0.font = .systemFont(ofSize: 16.0, weight: .semibold)
                    }
                    .inset(uniform: 10.0)
                    .pointerInteraction()
                )
            )
            
            col.add(
                child: InteractiveElement(
                    content: Label(text: "A Label (Rounded)") {
                        $0.color = .darkGray
                        $0.font = .systemFont(ofSize: 16.0, weight: .semibold)
                    }
                    .inset(uniform: 10.0)
                    .pointerInteraction { view, _ in
                        .effect(.automatic, .verticalBeam(length: view.bounds.height))
                    }
                )
            )
            
            col.add(
                child: InteractiveElement(
                    content: Image(image: UIImage(systemName: "square.and.pencil"))
                        .constrainedTo(width: .absolute(44.0), height: .absolute(44.0))
                        .inset(uniform: 10.0)
                        .pointerInteraction()
                )
            )
        }
        .scrollable {
            $0.alwaysBounceVertical = true
        }
    }
    
    struct InteractiveElement : ProxyElement {

        var content : Element
        
        var elementRepresentation: Element {
            self.content
                .inset(uniform: 30.0)
                .box(
                    background: .init(white: 0.95, alpha: 1.0),
                    corners: .rounded(radius: 20.0),
                    borders: .solid(color: .init(white: 0.90, alpha: 1.0), width: 4.0)
                )
        }
    }
}

#endif
