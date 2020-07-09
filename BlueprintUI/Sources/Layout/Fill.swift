//
//  Fill.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 7/9/20.
//

import UIKit


/// An element which wraps a child element, and takes up all the available space vended to it by its
/// parent element. Use this when you want an element to take up all the space it possibly can during a layout pass.
public struct Fill : Element {
    
    /// The element being wrapped and filled to fit the parent.
    public var wrapped : Element
    
    /// The axes that should be filled.
    public var axes : Axes
    
    /// Creates a new `Fill` element along the given `Axes`.
    public init(along axes : Axes = .both, wrapping : Element) {
        self.axes = axes
        self.wrapped = wrapping
    }
    
    // MARK: Element
    
    public var content: ElementContent {
        ElementContent(child: self.wrapped, layout: Layout(axes: self.axes))
    }
    
    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        nil
    }
    
    private struct Layout : SingleChildLayout {
        
        var axes : Axes
        
        func layout(size: CGSize, child: Measurable) -> LayoutAttributes {
            LayoutAttributes(size: size)
        }
        
        func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {
            self.axes.measure(in: constraint, child: child)
        }
    }
}


public extension Fill {
    
    /// The available `Axes` that a `Fill` element can fill along.
    ///
    /// You can fill along the `.horizontal` axis, `.vertical` axis,
    /// or both axes by using the `.both` option.
    enum Axes : Equatable {
        
        /// Fills along the `.horizontal` axis only, using the height provided
        /// by the child for the filled width.
        case horizontal
        
        /// Fills along the `.vertical` axis only, using the width provided
        /// by the child for the filled height.
        case vertical
        
        /// The element will be filled along both the `.horizontal` and `.vertical` axes;
        /// identical to `constraint.maximum` provided by the parent element.
        case both
        
        func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {
            switch self {
            case .horizontal:
                let size = child.measure(in: constraint)
                return CGSize(width: constraint.width.maximum, height: size.height)
                
            case .vertical:
                let size = child.measure(in: constraint)
                return CGSize(width: size.width, height: constraint.height.maximum)
                
            case .both:
                return constraint.maximum
            }
        }
    }
}


public extension Element {
    
    /// Wrap the element in a `Fill` element, so that it will take up the maximum space it is allowed to
    /// during layout and measurement passes.
    func fill(along axes : Fill.Axes = .both) -> Fill {
        Fill(along: axes, wrapping: self)
    }
}
