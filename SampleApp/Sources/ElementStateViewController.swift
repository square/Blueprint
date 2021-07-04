//
//  ElementStateViewController.swift
//  SampleApp
//
//  Created by Kyle Van Essen on 7/3/21.
//  Copyright © 2021 Square. All rights reserved.
//

import UIKit
import BlueprintUI
import BlueprintUICommonControls


final class ElementStateViewController: UIViewController {
    
    let blueprintView = BlueprintView()

    override func loadView() {
        blueprintView.backgroundColor = .white
        self.view = blueprintView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        update()
        
        self.navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "Reload", style: .plain, target: self, action: #selector(update)),
            UIBarButtonItem(title: "Reload Loop", style: .plain, target: self, action: #selector(updateLoop))
        ]
    }
    
    @objc func updateLoop() {
        for _ in 0...100 {
            autoreleasepool {
                self.update()
            }
        }
    }

    @objc func update() {
        
        let start = Date()
        
        self.blueprintView.element = element
        self.blueprintView.layoutIfNeeded()
        
        let end = Date()
        print("Layout Time: \(end.timeIntervalSince(start))")
    }

    var element: Element {
        Column { column in
            column.horizontalAlignment = .fill
            column.verticalUnderflow = .growUniformly
            
            for _ in 1...500 {
                column.addFixed(
                    child: TestPost(
                        title: "This is a test post",
                        detail: "This is some detail in the post."
                    )
                )
            }
        }
        .scrollable {
            $0.alwaysBounceVertical = true
        }
    }
}


fileprivate struct TestPost : ProxyElement, Equatable, EquatableElement {
    
    var title : String
    var detail : String
    
    var elementRepresentation: Element {
        EnvironmentReader { env in
            
            _ = env.safeAreaInsets
            
            return Row { row in
                row.verticalAlignment = .center
                row.horizontalUnderflow = .growUniformly
                row.minimumHorizontalSpacing = 10
                
                row.addFixed(
                    child: Box(backgroundColor: .systemGray, cornerStyle: .rounded(radius: 4.0))
                        .constrainedTo(width: 70, height: 70)
                )
                
                row.addFlexible(child: Column { col in
                    col.minimumVerticalSpacing = 10.0
                    
                    col.addFixed(
                        child: Label(text: self.title) {
                            $0.font = .systemFont(ofSize: 18.0, weight: .semibold)
                        }
                    )
                    
                    col.addFixed(
                        child: Label(text: self.detail) {
                            $0.font = .systemFont(ofSize: 16.0, weight: .regular)
                        }
                    )
                })
            }
            .inset(uniform: 15.0)
        }
    }
}
