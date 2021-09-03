import UIKit

/// Represents an a proportional relationship between width and height.
public struct AspectRatio {
    /// A 1:1 aspect ratio.
    public static let square = AspectRatio(ratio: 1)

    /// The width:height ratio value.
    public var ratio: CGFloat

    /// Initializes with a width & height ratio.
    ///
    /// - Parameter width: The relative width of the ratio.
    /// - Parameter height: The relative height of the ratio.
    public init(width: CGFloat, height: CGFloat) {
        self.init(ratio: width / height)
    }

    /// Initializes with a specific ratio.
    ///
    /// - Parameter ratio: The width:height ratio.
    public init(ratio: CGFloat) {
        self.ratio = ratio
    }

    func height(forWidth width: CGFloat) -> CGFloat {
        width / ratio
    }

    func width(forHeight height: CGFloat) -> CGFloat {
        height * ratio
    }

    func size(forHeight height: CGFloat) -> CGSize {
        CGSize(width: width(forHeight: height), height: height)
    }

    func size(forWidth width: CGFloat) -> CGSize {
        CGSize(width: width, height: height(forWidth: width))
    }
}
