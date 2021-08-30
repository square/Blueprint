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

    public private(set) var layout: StackLayout = .defaultColumn

    public init() {}

    /// Initializer using result builder to declaritively build up a stack.
    /// - Parameters:
    ///   - layout: A StackLayout describing the column's layout
    ///   - elements: A block containing all elements to be included in the stack.
    /// - Note: If element is a StackChild, then traits and key will be pulled from the element, otherwise defaults are passed through.
    public init(
        layout: StackLayout = .defaultColumn,
        @ElementBuilder<StackChild> elements: () -> [StackChild]
    ) {
        self.init(elementsBuilder: elements)
        self.layout = layout
    }

    /// Initializer using result builder to declaritively build up a stack.
    /// - Parameters:
    ///   - alignment: Determines the cross-axis layout
    ///   - verticalUnderflow: Determines the layout when there is extra free space available.
    ///   - verticalOverflow: Determines the layout when there is not enough space to fit all children as measured.
    ///   - horizontalAlignment: Specifies how children will be aligned horizontally.
    ///   - minimumVerticalSpacing: Spacing in between elements.
    ///   - elements: A block containing all elements to be included in the stack.
    /// - Note: If element is a StackChild, then traits and key will be pulled from the element, otherwise defaults are passed through.
    public init(
        alignment: StackLayout.Alignment = StackLayout.defaultColumn.alignment,
        verticalUnderflow: StackLayout.UnderflowDistribution = StackLayout.defaultColumn.underflow,
        verticalOverflow: StackLayout.OverflowDistribution = StackLayout.defaultColumn.overflow,
        horizontalAlignment: ColumnAlignment = StackLayout.defaultColumn.columnAlignment,
        minimumVerticalSpacing: CGFloat = StackLayout.defaultColumn.minimumSpacing,
        @ElementBuilder<StackChild> elements: () -> [StackChild]
    ) {
        var layout: StackLayout = .init(axis: StackLayout.defaultColumn.axis, alignment: alignment)
        layout.underflow = verticalUnderflow
        layout.overflow = verticalOverflow
        layout.alignment = horizontalAlignment.stackAlignment
        layout.minimumSpacing = minimumVerticalSpacing
        self.init(layout: layout, elements: elements)
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
