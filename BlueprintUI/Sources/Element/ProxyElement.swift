import UIKit

/// Custom elements commonly use another element to actually display content. For example, a profile element might
/// display an image and a few labels inside a `Column` element. The ProxyElement protocol is provided to make that
/// task easier.
///
/// Conforming types only need to implement `elementRepresentation` in order to generate an element that will be
/// displayed.
public protocol ProxyElement: Element {

    /// Returns an element that represents the entire content of this element.
    var elementRepresentation: Element { get }
}

extension ProxyElement {

    public var content: ElementContent {

        /// This is a somewhat clever optimization to essentially "collapse"
        /// `ProxyElement` instances out of the element tree, in order to speed
        /// up layout quite substantially, so that every layer in the tree does not need
        /// to be tracked, iterated, etc. `ProxyElement` is layout neutral,
        /// meaning that it doesn't really have measurements or state of its own,
        /// so we can skip it for our purposes.
        ///
        /// If you had an element hierarchy like this:
        /// ```
        /// Box
        ///   Inset
        ///     Centered (Proxy)
        ///       Aligned
        ///         Label (Proxy)
        ///           AttributedLabel
        /// ```
        /// You can see that 2 of the elements are proxies. If we collapse these:
        /// ```
        /// Box
        ///   Inset
        ///     Aligned
        ///       AttributedLabel
        /// ```
        /// The depth of the tree is reduced, which substantially improves performance
        /// for very deep `ProxyElement` based hierarchies, or for hirearchies with many `ProxyElement` elements.
        ///
        /// This optimization relies upon the `ProxyElement` truly having no state of its own; if we ever introduce
        /// other state onto `ProxyElement`, we will need to remove this optimization or at least opt those
        /// elemenets out of the optimizations, to ensure the `ProxyElement` has a backing `ElementState`.

        elementRepresentation.content
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        elementRepresentation.backingViewDescription(with: context)
    }
}
