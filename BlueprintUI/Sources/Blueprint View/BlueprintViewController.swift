//
//  BlueprintViewController.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 2/18/20.
//

import UIKit


public final class BlueprintViewController : UIViewController
{
    //
    // MARK: Public Properties
    //
    
    var element : Element? {
        get {
            switch self.viewState {
            case .notLoaded(let element): return element
            case .loaded(let view): return view.element
            }
        }
        
        set {
            self.set(element: newValue)
        }
    }
    
    //
    // MARK: Private Properties
    //
        
    private var viewState : ViewState = .notLoaded(nil)
    
    private enum ViewState {
        case notLoaded(Element?)
        case loaded(BlueprintView)
    }
    
    //
    // MARK: Public Methods
    //
    
    public func set(animated : Bool = UIView.isInAnimationBlock, element: Element?)
    {
        switch self.viewState {
        case .notLoaded(_): self.viewState = .notLoaded(element)
        case .loaded(let view): view.set(animated: animated, element: element)
        }
    }
    
    //
    // MARK: UIViewController
    //
    
    public override func loadView() {
        
        switch self.viewState {
        case .notLoaded(let element):
            let view = BlueprintView(element: element)
            self.view = view
            self.viewState = .loaded(view)
            
        case .loaded(_): fatalError()
        }
    }
}
