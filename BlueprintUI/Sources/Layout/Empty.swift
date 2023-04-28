import UIKit


///
/// An empty `Element` which has no size and draws no content.
///
public struct Empty: Element {

    public init() {}

    public var content: ElementContent {
        ElementContent(intrinsicSize: .zero)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
}
