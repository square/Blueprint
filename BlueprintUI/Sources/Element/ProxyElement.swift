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

    public func content(in env : Environment) -> ElementContent {
        return ElementContent(child: elementRepresentation)
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }

}
