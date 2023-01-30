import UIKit

/// An element that dynamically builds its content based on the available space.
///
/// Use this element to build elements whose contents may change responsively to
/// different layouts.
///
/// ## Example
///
/// ```swift
/// GeometryReader { (geometry) -> Element in
///     let image: UIImage
///     switch geometry.constraint.width.maximum {
///     case ..<100:
///         image = UIImage(named: "small")!
///     case 100..<500:
///         image = UIImage(named: "medium")!
///     default:
///         image = UIImage(named: "large")!
///     }
///     return Image(image: image)
/// }
/// ```
///
/// ## ⚠️ Important Performance Note
/// Depending on the structure of your `GeometryReader` return value
/// and parent elements that the reader is contained within, you may end up invalidating
/// caching used during layouts. For example: when the reader is measured multiple times
/// to determine the final layout or size of a parent element such as a `Row` with
/// multiple flexible elements.
///
/// To alleviate this and ensure caching occurs, wrap each returned element in a `.keyed(someKey)`
/// to uniquely identify each possible return value and preserve it in the caching tree.
///
/// ### Examples
///
/// ```swift
/// GeometryReader { proxy in
///
///     // 🚫 If measured in two or more sizes above and below
///     // 100 pts, the cache for Label.1 will be thrown out
///     // due to differing content.
///
///     if proxy.constraint.width < 100 {
///         Label(text: "Short string")
///     } else {
///         Label(text: "A longer string with more info.")
///     }
/// }
///
/// GeometryReader { proxy in
///
///     // 🚫 Similar to above, but differing syntax.
///     // If measured in two or more sizes, above and below
///     // 100 pts, the cache for ID(Label.1) will be thrown out
///     // due to differing content.
///
///     let string = {
///         if proxy.constraint.width < 100 {
///             return "Short string"
///         } else {
///             return "A longer string with more info."
///         }
///     }()
///
///     return Label(text: string)
/// }
///
/// GeometryReader { proxy in
///
///     // ✅ Will create two separate child elements,
///     // with two IDs, ID(Label.short.1), and ID(Label.long.1),
///     // allowing the two elements (and any child elements)
///     // to maintain their own separate branches in the cache tree,
///     // even though only one element will be returned during the layout.
///
///     if proxy.constraint.width < 100 {
///         Label(text: "Short string").keyed("short")
///     } else {
///         Label(text: "A longer string with more info.").keyed("long")
///     }
/// }
/// ```
public struct GeometryReader: Element {
    /// Return the contents of this element based on the current layout.
    var elementRepresentation: (GeometryProxy) -> Element

    public init(elementRepresentation: @escaping (GeometryProxy) -> Element) {
        self.elementRepresentation = elementRepresentation
    }

    public var content: ElementContent {
        ElementContent { constraint, environment -> Element in
            self.elementRepresentation(GeometryProxy(environment: environment, constraint: constraint))
        }
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
}

/// Contains information about the current layout being measured by GeometryReader
public struct GeometryProxy {
    var environment: Environment

    /// The size constraint of the element being laid out.
    public var constraint: SizeConstraint

    /// Measure the given element, constrained to the same size as the `GeometryProxy` itself (unless a constraint is explicitly provided).
    public func measure(element: Element, in explicit: SizeConstraint? = nil) -> CGSize {
        element.content.measure(in: explicit ?? constraint, environment: environment)
    }
}
