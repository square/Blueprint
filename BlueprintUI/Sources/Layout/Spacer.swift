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

    /// Initializes a new spacer with the given width and height.
    public init(width: CGFloat = 0.0, height: CGFloat = 0.0) {
        self.init(
            size: CGSize(width: width, height: height)
        )
    }

    /// Initializes a new spacer with the given value for the width and height.
    public init(_ value: CGFloat) {
        self.init(
            size: CGSize(width: value, height: value)
        )
    }

    public var content: ElementContent {
        ElementContent(intrinsicSize: size)
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }

}
