//
//  AnimatableViewProperties.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 2/17/20.
//

import UIKit


/**
 Represents the animatable properties on a UIView instance.
 
 Used by `TransitionAnimation` in order to prepare for and apply
 animations during appearance transitions.
 
 Each property is optional: If set, it will be applied to the view.
 If not set, it will not be applied and the current value on the view
 instance will be respected.

 The following properties of the UIView class are animatable:
 
 `frame`
 `bounds`
 `center`
 `transform`
 `alpha`
 `backgroundColor`
 
 */
public struct AnimatableViewProperties : Equatable {
    
    /// The alpha of the view.
    public var alpha : CGFloat?
    
    /// The background color of the view.
    public var backgroundColor : UIColor?
    
    /// The bounds of the view.
    /// If you set bounds, you should also set center, but not frame.
    public var bounds : CGRect?
    
    /// The center of the view.
    /// If you set center, you should also set bounds, but not frame.
    public var center : CGPoint?
    
    /// The frame of the view.
    /// If you set this property, you should not set bounds, center, or transform.
    public var frame : CGRect?
    
    /// The transform applied to the view.
    /// If you set this property, you should set bounds and center to position the view, not frame.
    public var transform : CGAffineTransform?
    
    /**
     Creates a new instance with all properties copied from the provided `UIView`.
     
     If you do not want your instance to have all these properties set, clear them in the `configure` block.
     */
    public init(withPropertiesFrom view : UIView, configure : (inout AnimatableViewProperties) -> () = { _ in })
    {
        self.alpha = view.alpha
        self.backgroundColor = view.backgroundColor
        self.bounds = view.bounds
        self.center = view.center
        self.frame = view.frame
        self.transform = view.transform
        
        configure(&self)
    }
    
    /// Creates new `AnimatableViewProperties` with the provided options.
    public init(
        alpha : CGFloat? = nil,
        backgroundColor : UIColor? = nil,
        bounds : CGRect? = nil,
        center : CGPoint? = nil,
        frame : CGRect? = nil,
        transform : CGAffineTransform? = nil
    ) {
        self.alpha = alpha
        self.backgroundColor = backgroundColor
        self.bounds = bounds
        self.center = center
        self.frame = frame
        self.transform = transform
    }
    
    /**
     Applies the set properties to the given view.
     
     This method does not animate any properties. Thus, you should
     call this method within a `UIView.animate(with...` block.
     */
    public func apply(to view : UIView)
    {
        if let alpha = self.alpha {
            view.alpha = alpha
        }
        
        if let backgroundColor = self.backgroundColor {
            view.backgroundColor = backgroundColor
        }
        
        if let bounds = self.bounds {
            view.bounds = bounds
        }
        
        if let center = self.center {
            view.center = center
        }
        
        if let frame = self.frame {
            view.frame = frame
        }
        
        if let transform = self.transform {
            view.transform = transform
        }
    }
}
