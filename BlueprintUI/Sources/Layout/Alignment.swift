import CoreGraphics

/// An alignment in both axes.
public struct Alignment: Equatable {
    /// A guide marking the center of the element.
    public static let center = Alignment(horizontal: .center, vertical: .center)

    /// A guide marking the leading edge of the element.
    public static let leading = Alignment(horizontal: .leading, vertical: .center)
    /// A guide marking the trailing edge of the element.
    public static let trailing = Alignment(horizontal: .trailing, vertical: .center)

    /// A guide marking the top edge of the element.
    public static let top = Alignment(horizontal: .center, vertical: .top)
    /// A guide marking the bottom edge of the element.
    public static let bottom = Alignment(horizontal: .center, vertical: .bottom)

    /// A guide marking the top and leading edges of the element.
    public static let topLeading = Alignment(horizontal: .leading, vertical: .top)
    /// A guide marking the top and trailing edges of the element.
    public static let topTrailing = Alignment(horizontal: .trailing, vertical: .top)

    /// A guide marking the bottom and leading edges of the element.
    public static let bottomLeading = Alignment(horizontal: .leading, vertical: .bottom)
    /// A guide marking the bottom and trailing edges of the element.
    public static let bottomTrailing = Alignment(horizontal: .trailing, vertical: .bottom)

    /// The alignment on the horizontal axis.
    public var horizontal: HorizontalAlignment
    /// The alignment on the vertical axis.
    public var vertical: VerticalAlignment

    /// Creates an instance with the given horizontal and vertical alignments.
    public init(horizontal: HorizontalAlignment, vertical: VerticalAlignment) {
        self.horizontal = horizontal
        self.vertical = vertical
    }
}

/// Types used to identify alignment guides.
///
/// Types conforming to `AlignmentID` have a corresponding alignment guide value,
/// typically declared as a static constant property of `HorizontalAlignment` or
/// `VerticalAlignment`.
///
public protocol AlignmentID {

    /// Returns the value of the corresponding guide, in `context`, when not
    /// otherwise set in `context`.
    static func defaultValue(in context: ElementDimensions) -> CGFloat
}

/// An alignment position along the horizontal axis.
public struct HorizontalAlignment: Equatable, CustomStringConvertible {

    var id: AlignmentID.Type

    /// Creates an instance with the given ID.
    ///
    /// Note: each instance should have a unique ID.
    public init(_ id: AlignmentID.Type) {
        self.id = id
    }

    public static func == (lhs: HorizontalAlignment, rhs: HorizontalAlignment) -> Bool {
        lhs.id == rhs.id
    }

    public var description: String {
        "\(id)"
    }
}

/// An alignment position along the vertical axis.
public struct VerticalAlignment: Equatable, CustomStringConvertible {

    var id: AlignmentID.Type

    /// Creates an instance with the given ID.
    ///
    /// Note: each instance should have a unique ID.
    public init(_ id: AlignmentID.Type) {
        self.id = id
    }

    public static func == (lhs: VerticalAlignment, rhs: VerticalAlignment) -> Bool {
        lhs.id == rhs.id
    }

    public var description: String {
        "\(id)"
    }
}

extension HorizontalAlignment {
    enum Leading: AlignmentID {
        static func defaultValue(in context: ElementDimensions) -> CGFloat {
            0
        }
    }

    /// A guide marking the leading edge of the element.
    public static let leading = HorizontalAlignment(Leading.self)

    enum Center: AlignmentID {
        static func defaultValue(in d: ElementDimensions) -> CGFloat {
            d.width / 2
        }
    }

    /// A guide marking the horizontal center of the element.
    public static let center = HorizontalAlignment(Center.self)

    enum Trailing: AlignmentID {
        static func defaultValue(in d: ElementDimensions) -> CGFloat {
            d.width
        }
    }

    /// A guide marking the trailing edge of the element.
    public static let trailing = HorizontalAlignment(Trailing.self)
}

extension VerticalAlignment {
    enum Top: AlignmentID {
        static func defaultValue(in d: ElementDimensions) -> CGFloat {
            0
        }
    }

    /// A guide marking the top edge of the element.
    public static let top = VerticalAlignment(Top.self)

    enum Center: AlignmentID {
        static func defaultValue(in d: ElementDimensions) -> CGFloat {
            d.height / 2
        }
    }

    /// A guide marking the vertical center of the element.
    public static let center = VerticalAlignment(Center.self)

    enum Bottom: AlignmentID {
        static func defaultValue(in d: ElementDimensions) -> CGFloat {
            d.height
        }
    }

    /// A guide marking the bottom edge of the element.
    public static let bottom = VerticalAlignment(Bottom.self)
}

/// Internal typealias for convenience
typealias AlignmentGuide = (ElementDimensions) -> CGFloat
