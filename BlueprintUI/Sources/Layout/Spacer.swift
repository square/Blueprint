import UIKit

/// An element that does not display anything (it has neither children or a view).
///
/// `Spacer` simply takes up a specified amount of space within a layout.
public struct Spacer: Element {

    /// The size that this spacer will take in a layout.
    public var size: CGSize

    /// Initializes a new spacer with the given size.
    public init(size: CGSize) {
        self.size = size
    }

    public func content(in env : Environment) -> ElementContent {
        return ElementContent(intrinsicSize: size)
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }

}
