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

    public private(set) var layout: StackLayout = StackLayout(
        axis: .horizontal,
        alignment: Row.RowAlignment.top.stackAlignment
    )

    public init() {}

    /// Initializer using result builder to declaratively build up a stack.
    /// - Parameters:
    ///   - alignment: Specifies how children will be aligned vertically. Default: .top
    ///   - underflow: Determines the layout when there is extra free space available. Default: .spaceEvenly
    ///   - overflow: Determines the layout when there is not enough space to fit all children as measured. Default: .condenseProportionally
    ///   - minimumSpacing: Spacing in between elements. Default: 0
    ///   - elements: A block containing all elements to be included in the stack.
    /// - Note: If element is a plain Element, then that Element will be implicitly converted into a `StackLayout.Child` with default values
    public init(
        alignment: RowAlignment = .top,
        underflow: StackLayout.UnderflowDistribution = .spaceEvenly,
        overflow: StackLayout.OverflowDistribution = .condenseProportionally,
        minimumSpacing: CGFloat = 0,
        @ElementBuilder<StackLayout.Child> elements: () -> [StackLayout.Child]
    ) {
        var layout: StackLayout = .init(axis: .horizontal, alignment: alignment.stackAlignment)
        layout.underflow = underflow
        layout.overflow = overflow
        layout.minimumSpacing = minimumSpacing
        self.init(elementsBuilder: elements)
        self.layout = layout
    }

    public var horizontalUnderflow: StackLayout.UnderflowDistribution {
        get { layout.underflow }
        set { layout.underflow = newValue }
    }

    public var horizontalOverflow: StackLayout.OverflowDistribution {
        get { layout.overflow }
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
        get { layout.minimumSpacing }
        set { layout.minimumSpacing = newValue }
    }

}
