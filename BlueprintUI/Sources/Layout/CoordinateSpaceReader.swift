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
///     .readCoordinateSpace(isActive: true) { context in
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
    public var onChange : (CoordinateSpaceTracking.Context) -> ()
    
    // MARK: Initialization
    
    /// Creates a new instance of the reader.
    public init(
        isActive : Bool,
        wrapping : Element,
        onChange : @escaping (CoordinateSpaceTracking.Context) -> ()
    ) {
        self.isActive = true
        self.wrapping = wrapping
        self.onChange = onChange
    }
    
    // MARK: Element
    
    public var content: ElementContent {
        ElementContent(child: self.wrapping)
    }
    
    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        TouchPassthroughView.describe { config in
            config.trackPosition = .init(
                isActive: self.isActive,
                onChange: self.onChange
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
    ///     .readCoordinateSpace(isActive: true) { context in
    ///          // Send the provided coordinate space along..
    ///     }
    /// }
    /// ```
    public func readCoordinateSpace(
        isActive : Bool,
        onChange : @escaping CoordinateSpaceTracking.Callback
    ) -> CoordinateSpaceReader
    {
        .init(
            isActive: isActive,
            wrapping: self,
            onChange: onChange
        )
    }
}
