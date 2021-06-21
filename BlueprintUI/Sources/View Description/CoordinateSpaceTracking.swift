//
//  CoordinateSpaceTracking.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 6/20/21.
//

///
/// Info required for tracking a coordinate space on a view-backed Blueprint element.
///
public struct CoordinateSpaceTracking {
    
    /// Should tracking be enabled.
    /// Useful if you'd like to conditionally based on some internal state like showing a tutorial or popover.
    public var isActive : Bool
    
    /// Called when the position of the element changes on screen.
    public var onChange : Callback
    
    /// Creates a new `CoordinateSpace` instance to track the displayed view.
    public init(
        isActive: Bool,
        onChange: @escaping Callback
    ) {
        self.isActive = isActive
        self.onChange = onChange
    }
}


extension CoordinateSpaceTracking {
    
    /// When observing the coordinate space of an element, provides the callback when
    /// then position of the element changes.
    public typealias Callback = (Context) -> ()
    
    /// Info passed to the listeners of an element's coordinate space.
    public struct Context {
        /// The coordinate space of the element.
        public var element : UICoordinateSpace
        
        /// The coordinate space of the element's `BlueprintView`.
        public var blueprintView : UICoordinateSpace
        
        /// The coordinate space of the highest superview in the element's hierarchy.
        /// If the element is in a window, this will be the window's coordinate space.
        public var top : UICoordinateSpace
        
        /// The coordinate space of the window the element is in.
        public var window : UICoordinateSpace?
    }
}
