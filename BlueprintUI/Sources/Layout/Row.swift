import UIKit

/// Displays a list of items in a linear horizontal layout.
public struct Row: StackElement {
    /// Describes how the row's children will be vertically aligned.
    public enum RowAlignment: Equatable {
        /// Children will be stretched to fit the vertical size of the row.
        case fill

        /// Using the specified alignment, children will be aligned relatively to each other, and
        /// then all the contents will be aligned to the row's bounding box.
        ///
        /// This case can be used for custom alignments. For common alignments you can use the
        /// existing static instances`top`, `center`, and `bottom`.
        ///
        case align(to: VerticalAlignment)

        /// Children will be aligned to the top edge of the row.
        public static let top = RowAlignment.align(to: .top)
        /// Children will be vertically centered in the row.
        public static let center = RowAlignment.align(to: .center)
        /// Children will be aligned to the bottom edge of the row.
        public static let bottom = RowAlignment.align(to: .bottom)

        /// Children will be aligned to the top edge of the row.
        @available(*, deprecated, renamed: "top")
        public static let leading = RowAlignment.top

        /// Children will be aligned to the bottom edge of the row.
        @available(*, deprecated, renamed: "bottom")
        public static let trailing = RowAlignment.bottom

        init(_ stackAlignment: StackLayout.Alignment) {
            switch stackAlignment {
            case .fill:
                self = .fill
            case let .align(to: id):
                self = .align(to: VerticalAlignment(id))
            }
        }

        var stackAlignment: StackLayout.Alignment {
            switch self {
            case .fill:
                return .fill
            case let .align(to: alignment):
                return .align(to: alignment.id)
            }
        }
    }

    public var children: [(element: Element, traits: StackLayout.Traits, key: AnyHashable?)] = []

    private (set) public var layout = StackLayout(
        axis: .horizontal,
        alignment: RowAlignment.top.stackAlignment
    )

    public init() {}

    public var horizontalUnderflow: StackLayout.UnderflowDistribution {
        get { return layout.underflow }
        set { layout.underflow = newValue }
    }

    public var horizontalOverflow: StackLayout.OverflowDistribution {
        get { return layout.overflow }
        set { layout.overflow = newValue }
    }

    /// Specifies how children will be aligned vertically.
    public var verticalAlignment: RowAlignment {
        get {
            RowAlignment(layout.alignment)
        }
        set {
            layout.alignment = newValue.stackAlignment
        }
    }

    public var minimumHorizontalSpacing: CGFloat {
        get { return layout.minimumSpacing }
        set { layout.minimumSpacing = newValue }
    }

}
