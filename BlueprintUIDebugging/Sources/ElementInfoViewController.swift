//
//  ElementInfoViewController.swift
//  BlueprintUIDebugging
//
//  Created by Kyle Van Essen on 4/24/20.
//

import UIKit
import BlueprintUI
import BlueprintUICommonControls


final class ElementInfoViewController : UIViewController {
    
    let element : Element
        
    let blueprintView = BlueprintView()
    
    init(element : Element) {
        self.element = element
        
        super.init(nibName: nil, bundle: nil)
        
        self.title = "Inspector"
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func loadView() {
        self.view = self.blueprintView
        //self.blueprintView.debugging.showElementFrames = .viewBacked
        
        self.blueprintView.element = Content(
            presenting: self.element,
            presentOn: self
        )
        
        self.blueprintView.layoutIfNeeded()
    }
}

fileprivate struct Content : ProxyElement {
    var presenting : Element
    
    weak var presentOn : UIViewController?
    
    var elementRepresentation: Element {
        Screen(
            sections: [
                .init(
                    title: "Preview",
                    element: Preview(presenting: self.presenting)
                ),
                
                .init(
                    title: "Layers",
                    element: ThreeDVisualization(presenting: self.presenting)
                ),
                
                .init(
                    title: "Hierarchy",
                    element: RecursiveElements(presenting: self.presenting, onTap: { element in
                        self.presentOn?.present(
                            UINavigationController(rootViewController: ElementInfoViewController(element: element)),
                            animated: true
                        )
                    })
                ),
            ]
        )
    }
    
    struct Preview : ProxyElement {
        var presenting : Element
        
        var elementRepresentation: Element {
            ConstrainedSize(
                height: .atLeast(100.0),
                wrapping: Centered(Box(wrapping: self.presenting) {
                    $0.borderStyle = .solid(color: UIColor(white: 0.0, alpha: 0.25), width: 1.0)
                    $0.cornerStyle = .rounded(radius: 4.0)
                })
            )
        }
    }
    
    struct ThreeDVisualization : ProxyElement {
        var presenting : Element
        
        var elementRepresentation: Element {
            let snapshot = FlattenedElementSnapshot(
                element: self.presenting,
                sizeConstraint: SizeConstraint(UIScreen.main.bounds.size)
            )
            
            return ThreeDElementVisualization(snapshot: snapshot)
        }
    }
    
    struct RecursiveElements : ProxyElement {
        var presenting : Element
        var onTap : (Element) -> ()
        
        var elementRepresentation: Element {
            Column {
                $0.horizontalAlignment = .fill
                $0.minimumVerticalSpacing = 10.0
                
                let list = self.presenting.recursiveElementList()
                
                for element in list {
                    $0.add(
                        child: DebuggingScreenContent.ElementRow(
                            element: element.element,
                            depth: element.depth,
                            onTap: self.onTap
                        )
                    )
                }
            }
        }
    }
}
