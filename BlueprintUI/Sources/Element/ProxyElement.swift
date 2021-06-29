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
        elementRepresentation.content
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        elementRepresentation.backingViewDescription(with: context)
    }

}
