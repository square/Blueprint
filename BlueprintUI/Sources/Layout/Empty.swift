import UIKit


///
/// An empty `Element` which has no size and draws no content.
///
public struct Empty: Element, ComparableElement {

    public init() {}

    public var content: ElementContent {
        ElementContent(intrinsicSize: .zero)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }

    public func isEquivalent(to other: Empty) -> Bool {
        // Empty elements are always equivalent since they have no properties
        true
    }
}
