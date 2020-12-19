import UIKit

/// Conforming types represent a rectangular content area in a two-dimensional
/// layout space.
///
/// ***
///
/// The ultimate purpose of an element is to provide visual content. This can be
/// done in two ways:
///
/// - By providing a view description (`ViewDescription`).
///
/// - By providing child elements that will be displayed recursively within
///   the local coordinate space.
///
/// ***
///
/// A custom element might look something like this:
///
/// ```
/// struct MyElement: Element {
///
///     var backgroundColor: UIColor = .red
///
///     // Returns a single child element.
///     var content: ElementContent {
///         return ElementContent(child: Label(text: "😂"))
///     }
///
///     // Providing a view description means that this element will be
///     // backed by a UIView instance when displayed in a `BlueprintView`.
///     func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
///         return UIView.describe { config in
///             config.bind(backgroundColor, to: \.backgrouncColor)
///         }
///     }
///
/// }
/// ```
///
public protocol Element : _Blueprint_Elements_Should_Be_Value_Types {

    /// Returns the content of this element.
    ///
    /// Elements generally fall into two types:
    /// - Leaf elements, or elements that have no children. These elements commonly have an intrinsic size, or some
    ///   content that can be measured. Leaf elements typically instantiate their content with
    ///   `ElementContent(measurable:)` or similar.
    /// - Container elements: these element have one or more children, which are arranged by a layout implementation.
    ///   Container elements typically use methods like `ElementContent(layout:configure:)` to instantiate
    ///   their content.
    var content: ElementContent { get }

    /// Returns an (optional) description of the view that should back this element.
    ///
    /// In Blueprint, elements that are displayed using a live `UIView` instance are referred to as "view-backed".
    /// Elements become view-backed by returning a `ViewDescription` value from this method.
    ///
    /// - Parameter bounds: The bounds of this element after layout is complete.
    /// - Parameter subtreeExtent: A rectangle in the local coordinate space that contains any children.
    ///                            `subtreeExtent` will be nil if there are no children.
    ///
    /// - Returns: An optional `ViewDescription`.
    func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription?

}


//
// MARK: Value Type Validation
//


///
/// This protocol exists to enforce at compile time that your `Element` are value types like `struct` or `enum`.
///
/// It is very very unusual and usually an error to make an `Element` a `class` type. Blueprint's internal
/// implementation relies on the fact that passed in `Element` respect value semantics and are owned by the framework.
///
/// Notes
/// -----
/// You should really not make your `Element` be a `class`. If for some reason you really really want to do this,
/// (you should not do this unless you have a good reason, which you probably do not), then override the
/// `elements_should_be_value_types_by_overriding_this_method_i_acknowledge_i_am_in_hard_mode()`
/// method in your `Element` to opt out of this validation – but you probably shouldn't. If you must do this,
/// please ensure that your `Element` is either entirely immutable, or respects value semantics.
///
public protocol _Blueprint_Elements_Should_Be_Value_Types {
    func elements_should_be_value_types_by_overriding_this_method_i_acknowledge_i_am_in_hard_mode()
}


public extension _Blueprint_Elements_Should_Be_Value_Types {
    func elements_should_be_value_types_by_overriding_this_method_i_acknowledge_i_am_in_hard_mode() {}
}


public extension _Blueprint_Elements_Should_Be_Value_Types where Self : AnyObject {
    @available(*, unavailable, message: "Blueprint Elements should be value types, not classes.")
    func elements_should_be_value_types_by_overriding_this_method_i_acknowledge_i_am_in_hard_mode() {}
}
