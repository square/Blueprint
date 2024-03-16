import CoreGraphics

/// A normalized point in an element's coordinate space.
///
/// Use a unit point to represent a location in an element without having to know the element’s
/// rendered size. The point stores a value in each dimension that indicates the fraction of the
/// element’s size in that dimension — measured from the element’s origin — where the point appears.
/// For example, you can create a unit point that represents the center of any element by using the
/// value `0.5` for each dimension:
///
/// ```swift
/// let unitPoint = UnitPoint(x: 0.5, y: 0.5)
/// ```
///
/// To project the unit point into the rendered element’s coordinate space, multiply each component
/// of the unit point with the corresponding component of the element’s size:
///
/// ```swift
/// let projectedPoint = CGPoint(
///     x: unitPoint.x * size.width,
///     y: unitPoint.y * size.height
/// )
/// ```
///
/// You can perform this calculation yourself if you happen to know an element’s size, but Blueprint
/// typically does this for you to carry out operations that you request, like when you place a
/// subelement in a custom layout.
///
/// You can create custom unit points with explicit values, like the example above, or you can use
/// one of the built-in unit points, like ``zero``, ``center``, or ``topTrailing``. The built-in
/// values correspond to the alignment positions of the similarly named, built-in ``Alignment``
/// types.
///
/// - Note: A unit point with one or more components outside the range `[0, 1]` projects to a point
///   outside of the element.
///
public struct UnitPoint: Hashable {

    /// The normalized distance from the origin to the point in the horizontal direction.
    public var x: CGFloat
    /// The normalized distance from the origin to the point in the vertical direction.
    public var y: CGFloat

    /// Creates a unit point with the specified horizontal and vertical offsets.
    public init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }

    /// The origin of an element.
    public static let zero: UnitPoint = .init(x: 0, y: 0)

    /// A point that’s centered in an element.
    public static let center: UnitPoint = .init(x: 0.5, y: 0.5)

    /// A point that’s centered vertically on the leading edge of an element.
    public static let leading: UnitPoint = .init(x: 0, y: 0.5)

    /// A point that’s centered vertically on the trailing edge of an element.
    public static let trailing: UnitPoint = .init(x: 1, y: 0.5)

    /// A point that’s centered horizontally on the top edge of an element.
    public static let top: UnitPoint = .init(x: 0.5, y: 0)

    /// A point that’s centered horizontally on the bottom edge of an element.
    public static let bottom: UnitPoint = .init(x: 0.5, y: 1)

    /// A point that’s in the top leading corner of an element.
    public static let topLeading: UnitPoint = .init(x: 0, y: 0)

    /// A point that’s in the top trailing corner of an element.
    public static let topTrailing: UnitPoint = .init(x: 1, y: 0)

    /// A point that’s in the bottom leading corner of an element.
    public static let bottomLeading: UnitPoint = .init(x: 0, y: 1)

    /// A point that’s in the bottom trailing corner of an element.
    public static let bottomTrailing: UnitPoint = .init(x: 1, y: 1)
}
