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
    
    public typealias Callback = (Context) -> ()
    
    ///
    ///
    public struct Context {
        public var element : UICoordinateSpace
        
        public var blueprintView : UICoordinateSpace
        
        public var top : UICoordinateSpace
    }
}
