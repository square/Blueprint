import UIKit

/// Displays a list of items in a linear vertical layout.
public struct Column: StackElement {
    /// Describes how the column's children will be horizontally aligned.
    public enum ColumnAlignment: Equatable {
        /// Children will be stretched to fit the horizontal size of the column.
        case fill

        /// Using the specified alignment, children will be aligned relatively to each other, and
        /// then all the contents will be aligned to the column's bounding box.
        ///
        /// This case can be used for custom alignments. For common alignments you can use the
        /// existing static instances`leading`, `center`, and `trailing`.
        ///
        case align(to: HorizontalAlignment)

        /// Children will be aligned to the leading edge of the column.
        public static let leading = ColumnAlignment.align(to: .leading)
        /// Children will be horizontally centered in the column.
        public static let center = ColumnAlignment.align(to: .center)
        /// Children will be aligned to the trailing edge of the column.
        public static let trailing = ColumnAlignment.align(to: .trailing)

        init(_ stackAlignment: StackLayout.Alignment) {
            switch stackAlignment {
            case .fill:
                self = .fill
            case let .align(to: id):
                self = .align(to: HorizontalAlignment(id))
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
        axis: .vertical,
        alignment: Column.ColumnAlignment.leading.stackAlignment
    )

    public init() {}

    /// Creates a Column, using result builder syntax. Columns display a list of items in a vertical
    /// stack.
    ///
    ///     Column {
    ///         Label(text: "Welcome")
    ///
    ///         TextField(text: username)
    ///         TextField(text: password)
    ///
    ///         Button(
    ///             onTap: handleSignIn,
    ///             wrapping: Label(text: "Sign In")
    ///         )
    ///     }
    ///
    /// By default, each item in the column will be stretched or compressed with equal priority in
    /// the event of overflow or underflow. You can control this behavior by adding a
    /// `stackLayoutChild` modifier to an item.
    ///
    ///     Column {
    ///         ImportantHeader()
    ///             .stackLayoutChild(priority: .fixed)
    ///
    ///         LessImportantContent()
    ///     }
    ///
    /// You can also use this modifier to add keys and alignment guides. See `StackElement.add` for
    /// more information.
    ///
    /// ## See Also
    /// [StackElement.add()](x-source-tag://StackElement.add)
    ///
    /// - Parameters:
    ///   - alignment: Specifies how children will be aligned horizontally. Default: `.leading`
    ///   - underflow: Determines the layout when there is extra free space available. Default:
    ///     `.spaceEvenly`
    ///   - overflow: Determines the layout when there is not enough space to fit all children as
    ///     measured. Default: `.condenseProportionally`
    ///   - minimumSpacing: Spacing in between elements. Default: `0`
    ///   - elements: A block containing all elements to be included in the stack.
    public init(
        alignment: ColumnAlignment = .leading,
        underflow: StackLayout.UnderflowDistribution = .spaceEvenly,
        overflow: StackLayout.OverflowDistribution = .condenseProportionally,
        minimumSpacing: CGFloat = 0,
        @ElementBuilder<StackLayout.Child> elements: () -> [StackLayout.Child]
    ) {
        var layout: StackLayout = .init(axis: .vertical, alignment: alignment.stackAlignment)
        layout.underflow = underflow
        layout.overflow = overflow
        layout.minimumSpacing = minimumSpacing

        self.init(elementsBuilder: elements)
        self.layout = layout
    }

    public var verticalUnderflow: StackLayout.UnderflowDistribution {
        get { layout.underflow }
        set { layout.underflow = newValue }
    }

    public var verticalOverflow: StackLayout.OverflowDistribution {
        get { layout.overflow }
        set { layout.overflow = newValue }
    }

    /// Specifies how children will be aligned horizontally.
    public var horizontalAlignment: ColumnAlignment {
        get {
            ColumnAlignment(layout.alignment)
        }
        set {
            layout.alignment = newValue.stackAlignment
        }
    }

    public var minimumVerticalSpacing: CGFloat {
        get { layout.minimumSpacing }
        set { layout.minimumSpacing = newValue }
    }
}
