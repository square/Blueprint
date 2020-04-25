//
//  ChooseElementViewController.swift
//  BlueprintUIDebugging
//
//  Created by Kyle Van Essen on 4/24/20.
//

import UIKit
import BlueprintUI
import BlueprintUICommonControls


final class ChooseElementViewController : UIViewController {
    
    let elements : [Element]
        
    let blueprintView = BlueprintView()
    
    init(elements : [Element]) {
        self.elements = elements
        
        super.init(nibName: nil, bundle: nil)
        
        self.title = "Choose Element"
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func loadView() {
        self.view = self.blueprintView
        
        self.blueprintView.element = Content(elements: self.elements, presentOn: self)
        
        self.blueprintView.layoutIfNeeded()
    }
}


fileprivate struct Content : ProxyElement {
    let elements : [Element]
    weak var presentOn : UIViewController?
    
    var elementRepresentation: Element {
        Screen(
            sections: [
                .init(
                    title: "Elements",
                    detail:
                    """
                    You selected an element which overlays other elements entirely contained within the selected elements frame.

                    The below list is all those elements; please click on the one you want to inspect!
                    """,
                    element: Column {
                        $0.minimumVerticalSpacing = 20.0
                        
                        for element in self.elements {
                            $0.add(
                                child: Screen.ElementRow(
                                    element: element,
                                    depth: 0,
                                    onTap: { element in
                                        self.presentOn?.viewControllerToPresentOn.present(
                                            UINavigationController(rootViewController: ElementInfoViewController(element: element)),
                                            animated: true
                                        )
                                    }
                                )
                            )
                        }
                    }
                )
            ]
        )
    }
}
