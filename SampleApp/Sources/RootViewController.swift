//
//  RootViewController.swift
//  SampleApp
//
//  Created by Kyle Van Essen on 6/26/20.
//  Copyright © 2020 Square. All rights reserved.
//

import Foundation


import UIKit
import BlueprintUI
import BlueprintUICommonControls


final class RootViewController : UIViewController
{
    fileprivate var demos : [DemoItem] {
        [
            DemoItem(title: "Post List", onTap: { [weak self] in
                self?.push(PostsViewController())
            }),
            DemoItem(title: "ScrollView Keyboard Demo", onTap: { [weak self] in
                self?.push(ScrollViewKeyboardViewController())
            }),
            DemoItem(title: "GeometryReader Responsive Layout", onTap: { [weak self] in
                self?.push(ResponsiveViewController())
            }),
            DemoItem(title: "KeyboardReader Keyboard Observation", onTap: { [weak self] in
                self?.push(KeyboardReaderViewController())
            }),
        ]
    }
    
    override func loadView() {
        let blueprintView = BlueprintView(element: self.contents)

        self.view = blueprintView

        self.view.backgroundColor = .init(white: 0.9, alpha: 1.0)
    }

    var contents : Element {
        Column { column in
            column.minimumVerticalSpacing = 20.0
            column.horizontalAlignment = .fill
            
            self.demos.forEach { demo in
                column.add(child: demo)
            }
        }
        .constrainedTo(width: .within(300...400))
        .aligned(vertically: .top, horizontally: .center)
        .inset(uniform: 40.0)
        .scrollable(.fittingHeight) { scrollView in
            scrollView.alwaysBounceVertical = true
        }
    }
    
    private func push(_ viewController : UIViewController) {
        self.navigationController?.pushViewController(viewController, animated: true)
    }
}


fileprivate struct DemoItem : ProxyElement
{
    var title : String
    var onTap : () -> ()

    var elementRepresentation: Element {
         Label(text: self.title) { label in
            label.font = .systemFont(ofSize: 18.0, weight: .semibold)
        }
        .inset(uniform: 20.0)
        .box(
            background: .white,
            corners: .rounded(radius: 20.0),
            shadow: .simple(
                radius: 6.0,
                opacity: 0.2,
                offset: .init(width: 0, height: 3.0),
                color: .black
            )
        )
        .tappable {
            self.onTap()
        }
    }
}
