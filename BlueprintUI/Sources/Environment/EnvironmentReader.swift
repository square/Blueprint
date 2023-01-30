import CoreGraphics

/// An element that dynamically builds its content based on the `Environment`.
///
/// Use this element to build elements whose contents may change depending on the `Environment`.
///
/// ## Example
///
/// ```swift
/// EnvironmentReader { environment in
///     MyElement(
///         foo: environment.foo
///     )
/// }
/// ```
///
/// ## ⚠️ Important Performance Note
/// Depending on the structure of your `EnvironmentReader` return value
/// and parent elements that the reader is contained within, you may end up invalidating
/// caching used during layouts. For example: when the reader is measured multiple times
/// to determine the final layout or size of a parent element such as a `Row` with
/// multiple flexible elements, which also varies the contents of its `Environment` based
/// on an measured size.
///
/// To alleviate this and ensure caching occurs, wrap each returned element in a `.keyed(someKey)`
/// to uniquely identify each possible return value and preserve it in the caching tree.
///
/// ### Examples
///
/// ```swift
/// EnvironmentReader { environment in
///
///     // 🚫 If measured in environments which vary the `sizeClass`
///     // parameter the cache for Label.1 will be thrown out
///     // due to differing content.
///
///     if environment.sizeClass.isCompact {
///         Label(text: "Short string")
///     } else {
///         Label(text: "A longer string with more info.")
///     }
/// }
///
/// EnvironmentReader { environment in
///
///     // 🚫 Similar to above, but differing syntax.
///     // If measured in environments which vary the `sizeClass`
///     // parameter, the cache for ID(Label.1) will be thrown out
///     // due to differing content.
///
///     let string = {
///         if environment.sizeClass.isCompact {
///             return "Short string"
///         } else {
///             return "A longer string with more info."
///         }
///     }()
///
///     return Label(text: string)
/// }
///
/// EnvironmentReader { environment in
///
///     // ✅ Will create two separate child elements,
///     // with two IDs, ID(Label.short.1), and ID(Label.long.1),
///     // allowing the two elements (and any child elements)
///     // to maintain their own separate branches in the cache tree,
///     // even though only one element will be returned during the layout.
///
///     if environment.sizeClass.isCompact {
///         Label(text: "Short string").keyed("short")
///     } else {
///         Label(text: "A longer string with more info.").keyed("long")
///     }
/// }
/// ```
///
/// - seealso: `ProxyElement`
/// - seealso: `Environment`
///
public struct EnvironmentReader: Element {

    /// Return the contents of this element in the given environment.
    var elementRepresentation: (Environment) -> Element

    public init(elementRepresentation: @escaping (_ environment: Environment) -> Element) {
        self.elementRepresentation = elementRepresentation
    }

    public var content: ElementContent {
        ElementContent { _, environment in
            self.elementRepresentation(environment)
        }
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
}
