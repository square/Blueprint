/// Represents an a proportional relationship between width and height.
public struct AspectRatio {
    /// A 1:1 aspect ratio.
    public static let square = AspectRatio(x: 1, y: 1)

    /// The horizontal component of this ratio.
    public var x: CGFloat
    /// The vertical component of this ratio.
    public var y: CGFloat

    /// Initializes with a horizontal and vertical components.
    ///
    /// - Parameter x: The horizontal comonent.
    /// - Parameter y: The vertical component.
    public init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }

    func height(forWidth width: CGFloat) -> CGFloat {
        // TODO: round to screen scale when that lands
        return (width * y / x).rounded()
    }

    func width(forHeight height: CGFloat) -> CGFloat {
        // TODO: round to screen scale when that lands
        return (height * x / y).rounded()
    }
}
