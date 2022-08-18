//
//  ViewControllerHostingController.swift
//  SampleApp
//
//  Created by Kyle Van Essen on 8/18/22.
//  Copyright © 2022 Square. All rights reserved.
//

import BlueprintUI
import BlueprintUICommonControls
import UIKit


final class ViewControllerHostingController: UIViewController {

    let blueprintViewController: BlueprintViewController

    init() {
        blueprintViewController = BlueprintViewController()

        super.init(nibName: nil, bundle: nil)

        addChild(blueprintViewController)
        blueprintViewController.didMove(toParent: self)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func loadView() {
        super.loadView()

        view.addSubview(blueprintViewController.view)

        blueprintViewController.element = element
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        blueprintViewController.view.frame = view.bounds
    }

    fileprivate var element: Element {
        Column(alignment: .fill) {
            VCElement1().constrainedTo(height: .absolute(200))
            VCElement2().constrainedTo(height: .absolute(200))
            VCElement1().constrainedTo(height: .absolute(200))
            VCElement2().constrainedTo(height: .absolute(200))
        }
    }
}


fileprivate struct VCElement1: Element {

    var content: ElementContent {
        .init { size in
            size.maximum
        }
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        ViewController.describe { _ in }
    }

    private final class ViewController: UIViewController {

        override func loadView() {
            super.loadView()
            view.backgroundColor = .red
        }
    }
}

fileprivate struct VCElement2: Element {

    var content: ElementContent {
        .init { size in
            size.maximum
        }
    }

    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        ViewController.describe { _ in }
    }

    private final class ViewController: UIViewController {

        override func loadView() {
            super.loadView()
            view.backgroundColor = .blue
        }
    }
}
