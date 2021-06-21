//
//  CoordinateSpaceReader.swift
//  BlueprintUI
//
//  Created by Kyle Van Essen on 4/5/21.
//

import Foundation


///
/// Allows you to read the position of an on-screen element, receiving a callback whenever
/// its position changes (and the first time it is placed on screen). This is useful if you'd like to
/// position another view outside of the Blueprint hierarchy on top of this view, such as
/// a tooltip, popover, or other element.
///
/// **Note**  – You can receive a callback even without updating the element hierarchy.
/// This could happen by resizing the `BlueprintView` either explicitly,
/// or during a device rotation. You will also receive callbacks if the `BlueprintView`
/// is within a `ScrollView`, and the frame relative to the view's window changes, for example.
///
/// ### Performance Considerations
/// Creating a `CoordinateSpaceReader` creates a  `CADisplayLink` to
/// track the view's position to account for the `BlueprintView` potentially being
/// inside a `UIScrollView` or other view whose bounds may change during a layout in
/// a way that does not cause the `frame`, `center`, or `bounds` of the tracked view to change.
///
/// Because of this, please utilize the `isActive` property, passing `false` when you
/// do not need to track the position of the `Element` on screen. For example, if using the
/// ``CoordinateSpaceReader`` to track the position of an element to show a tooltip for a tutorial,
/// pass `false` when not showing the tooltip, and `true` when the tooltip is to be shown.
///
/// ```swift
/// var elementRepresentation : Element {
///     MyButton(title: "Add Item", onTap: ...)
///     .aligned(horizontally: .trailing)
///     .readCoordinateSpace(isActive: true) { position in
///          // Send the provided coordinate space along..
///     }
/// }
/// ```
public struct CoordinateSpaceReader : Element {
    
    // MARK: Properties
    
    /// Is reading / tracking of the coordinate space enabled.
    public var isActive : Bool
    
    /// The wrapped element.
    public var wrapping : Element
    
    /// Called when the coordinate space changes.
    public var onCoordinateSpaceChanged : (UICoordinateSpace) -> ()
    
    // MARK: Initialization
    
    /// Creates a new instance of the reader.
    public init(
        isActive : Bool,
        wrapping : Element,
        onCoordinateSpaceChanged : @escaping (UICoordinateSpace) -> ()
    ) {
        self.isActive = true
        self.wrapping = wrapping
        self.onCoordinateSpaceChanged = onCoordinateSpaceChanged
    }
    
    // MARK: Element
    
    public var content: ElementContent {
        ElementContent(child: self.wrapping)
    }
    
    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        TouchPassthroughView.describe { config in
            config.coordinateSpaceTracking = .init(
                isActive: self.isActive,
                onChange: self.onCoordinateSpaceChanged
            )
        }
    }
}


extension Element {
    
    ///
    /// Allows you to read the position of an on-screen element, receiving a callback whenever
    /// its position changes (and the first time it is placed on screen). This is useful if you'd like to
    /// position another view outside of the Blueprint hierarchy on top of this view, such as
    /// a tooltip, popover, or other element.
    ///
    /// **Note**  – You can receive a callback even without updating the element hierarchy.
    /// This could happen by resizing the `BlueprintView` either explicitly,
    /// or during a device rotation. You will also receive callbacks if the `BlueprintView`
    /// is within a `ScrollView`, and the frame relative to the view's window changes, for example.
    ///
    /// ### Performance Considerations
    /// Creating a `CoordinateSpaceReader` creates a  `CADisplayLink` to
    /// track the view's position to account for the `BlueprintView` potentially being
    /// inside a `UIScrollView` or other view whose bounds may change during a layout in
    /// a way that does not cause the `frame`, `center`, or `bounds` of the tracked view to change.
    ///
    /// Because of this, please utilize the `isActive` property, passing `false` when you
    /// do not need to track the position of the `Element` on screen. For example, if using the
    /// ``CoordinateSpaceReader`` to track the position of an element to show a tooltip for a tutorial,
    /// pass `false` when not showing the tooltip, and `true` when the tooltip is to be shown.
    ///
    /// ```swift
    /// var elementRepresentation : Element {
    ///     MyButton(title: "Add Item", onTap: ...)
    ///     .aligned(horizontally: .trailing)
    ///     .readCoordinateSpace(isActive: true) { position in
    ///          // Send the provided coordinate space along..
    ///     }
    /// }
    /// ```
    public func readCoordinateSpace(
        isActive : Bool,
        onChange : @escaping (UICoordinateSpace) -> ()
    ) -> CoordinateSpaceReader
    {
        CoordinateSpaceReader(isActive: isActive, wrapping: self, onCoordinateSpaceChanged: onChange)
    }
}


///
/// Info required for tracking a coordinate space on a view-backed Blueprint element.
///
public struct CoordinateSpaceTracking {
    
    /// Should tracking be enabled.
    /// Useful if you'd like to conditionally based on some internal state like showing a tutorial or popover.
    public var isActive : Bool
    
    /// Called when the position of the element changes on screen.
    public var onChange : (UICoordinateSpace) -> ()
    
    /// Creates a new `CoordinateSpace` instance to track the displayed view.
    public init(
        isActive: Bool,
        onChange: @escaping (UICoordinateSpace) -> ()
    ) {
        self.isActive = isActive
        self.onChange = onChange
    }
}
