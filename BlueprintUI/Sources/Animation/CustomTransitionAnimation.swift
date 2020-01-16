//
//  CustomTransitionAnimation.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 2/17/20.
//

import UIKit


/**
 Allows you to create a custom animation for Blueprint's appearance transitions.
 
 See individual methods for more information.
 */
public protocol CustomTransitionAnimation : AnyCustomTransitionAnimation {
        
    associatedtype ViewType : UIView
    
    /**
     Called to begin the animation in the direction specified for the provided view.
     
     The current properties of the view are provided, which are already applied to the view.
     
     Within this method, you may do anything you want to animate the view into place. For example,
     you may use a `CustomAnimation` to back your animation with a `CAAnimation` or a
     `CADisplayLink` driven animation.
     
     When this method is called, the view is already in its desired final position within the hierarchy.
     For appearance animations, if you want to animate the view from a different starting position or apply different attributes,
     you will need to do so within this method  within a `UIView.performWithoutAnimation` block.

     Important Note!
     =========
     When your animation is complete, you **must** call the completion block, otherwise
     Blueprint has no idea that your animation has completed. You may only call this block once.
     */
    func animate(
        direction : TransitionAnimation.Direction,
        with view : ViewType,
        currentProperties : AnimatableViewProperties,
        completion : @escaping (Bool) -> ()
    )
    
    /**
     Called once the animation has been completed.
     
     Use this method to clean up any state your animation may have required during execution.
     
     You do not need to implement this method.
     A default implementation of this method is provided, which does nothing.
     */
    func didEnd()
}


public protocol AnyCustomTransitionAnimation {
    
    func animateAny(
        direction : TransitionAnimation.Direction,
        with anyView : UIView,
        currentProperties : AnimatableViewProperties,
        completion : @escaping (Bool) -> ()
    )
    
    func didEnd()
}


public extension CustomTransitionAnimation {
    
    func didEnd() {}
    
    func animateAny(
        direction : TransitionAnimation.Direction,
        with anyView : UIView,
        currentProperties : AnimatableViewProperties,
        completion : @escaping (Bool) -> ()
    ) {
        guard let containerView = anyView as? TransitionContainerView else {
            fatalError()
        }
        
        let contentView = containerView.subviews.first
        
        guard let typedView = contentView as? Self.ViewType else {
            fatalError("CustomTransitionAnimation ('\(type(of: self))') Error: Animated view was not the expected type. Expected: '\(Self.ViewType.self)', Got: '\(type(of:anyView))'.")
        }
        
        self.animate(
            direction: direction,
            with: typedView,
            currentProperties: currentProperties,
            completion: completion
        )
    }
}

