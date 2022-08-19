//
//  BlueprintViewController.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 8/18/22.
//

import UIKit


public final class BlueprintViewController: UIViewController {

    public var element: Element? = nil {
        didSet {
            blueprintView?.element = element
        }
    }

    private var blueprintView: BlueprintView?

    // MARK: UIViewController

    public override func loadView() {
        blueprintView = BlueprintView(element: element)
        blueprintView?.viewController = self

        view = blueprintView
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    public override var shouldAutomaticallyForwardAppearanceMethods: Bool {
        false
    }
}
