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
    
    /// How the view is positioned – either by `frame`, or by `bounds` + `center`.
    public var position : Position?
    
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
        
        /// We use `bounds` + `center` and not `frame` in case there is a non-identity `transform`,
        /// because the frame is meaningless in that case (as it's been adjusted by the `transform`).
        self.position = .bounds(view.bounds, view.center)
        
        self.transform = view.transform
        
        configure(&self)
    }
    
    public static func properties(_ configure : (inout Self) -> ()) -> Self
    {
        var properties = Self()
        
        configure(&properties)
        
        return properties
    }
    
    /// Creates new `AnimatableViewProperties` with the provided options.
    public init(
        alpha : CGFloat? = nil,
        backgroundColor : UIColor? = nil,
        position: Position? = nil,
        transform : CGAffineTransform? = nil
    ) {
        self.alpha = alpha
        self.backgroundColor = backgroundColor
        self.position = position
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
        
        if let position = self.position {
            switch position {
            case .frame(let frame):
                view.frame = frame
                
            case .bounds(let bounds, let center):
                view.bounds = bounds
                view.center = center
            }
        }
        
        if let transform = self.transform {
            view.transform = transform
        }
    }
}


extension AnimatableViewProperties {
    
    /// How the position of a view should be set when applying animated properties.
    public enum Position : Equatable {
        /// The `frame` is applied to the view to drive the animation.
        case frame(CGRect)
        
        /// The `bounds` and `center` are applied to drive the animation.
        case bounds(CGRect, CGPoint)
    }
}
