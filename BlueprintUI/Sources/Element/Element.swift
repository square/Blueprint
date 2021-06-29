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
///     func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
///         return UIView.describe { config in
///             config.bind(backgroundColor, to: \.backgroundColor)
///         }
///     }
///
/// }
/// ```
///
public protocol Element {

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
    /// - Parameter context: The context this element is rendered in.
    ///
    /// - Returns: An optional `ViewDescription`.
    func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription?

}

/// The context passing to the `backingViewDescription` of an Element.
public struct ViewDescriptionContext {

    /// The bounds of this element after layout is complete.
    public var bounds: CGRect

    /// A rectangle in the local coordinate space that contains any children.
    /// This will be nil if there are no children.
    public var subtreeExtent: CGRect?

    /// The environment the element is rendered in.
    public var environment: Environment

    public init(bounds: CGRect, subtreeExtent: CGRect?, environment: Environment) {
        self.bounds = bounds
        self.subtreeExtent = subtreeExtent
        self.environment = environment
    }
}
