import UIKit

/// Describes a shadow that can be applied to text elements, like `Label`.
public struct TextShadow: Hashable {
    /// The blur radius of the shadow.
    public var radius: CGFloat

    /// The opacity of the shadow.
    public var opacity: CGFloat

    /// The offset of the shadow.
    public var offset: UIOffset

    /// The color of the shadow.
    public var color: UIColor

    public init(radius: CGFloat, opacity: CGFloat, offset: UIOffset, color: UIColor) {
        self.radius = radius
        self.opacity = opacity
        self.offset = offset
        self.color = color
    }
}
