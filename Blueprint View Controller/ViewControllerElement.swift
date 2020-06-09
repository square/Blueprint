//
//  ViewControllerElement.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 6/5/20.
//

import Foundation


public protocol ViewControllerElement : Element {
    
    /// The type of `UIViewController` to be presented.
    associatedtype UIViewControllerType : UIViewController

    /// Creates a `UIViewController` instance to be presented.
    func makeUIViewController() -> Self.UIViewControllerType

    /// Updates the presented `UIViewController` (and coordinator) to the latest
    /// configuration.
    func updateUIViewController(_ uiViewController: Self.UIViewControllerType)

    /// Cleans up the presented `UIViewController` (and coordinator) in
    /// anticipation of their removal.
    func dismantleUIViewController(_ uiViewController: Self.UIViewControllerType)
}


public extension ViewControllerElement {
    
    var content: ElementContent {
        ElementContent { constraint -> CGSize in
            constraint.maximum
        }
    }
    
    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        self.viewDescription(bounds: bounds)
    }
}

extension ViewControllerElement {
    func viewDescription(bounds : CGRect) -> ViewDescription {
        ViewControllerElementView<Self>.describe { config in
            config.apply {
                $0.element = self
            }
            
        }
    }
}


private final class ViewControllerElementView<Element:ViewControllerElement> : UIView {
    
    var element : Element {
        didSet {
            self.element.updateUIViewController(self.viewController)
        }
    }
    
    let viewController : Element.UIViewControllerType
    
    init(element : Element, frame: CGRect) {
        
        self.element = element
        self.viewController = self.element.makeUIViewController()
        
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        
        if let new = newSuperview {
            let blueprintView = self.findHostingBlueprintView()!
            
            blueprintView.hostingViewController!.addChild(self.viewController)
            self.viewController.didMove(toParent: blueprintView.hostingViewController!)
            self.addSubview(self.viewController.view)
        } else {
            
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.viewController.view.frame = self.bounds
    }
    
    deinit {
        self.element.dismantleUIViewController(self.viewController)
    }
}


fileprivate extension UIView {
    func findHostingBlueprintView() -> BlueprintView? {
        var view : UIView? = self
        
        while view != nil {
            if let view = view as? BlueprintView, view.hostingViewController != nil {
                return view
            } else {
                view = view?.superview
            }
        }
        
        return nil
    }
}
