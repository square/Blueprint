import UIKit

// MARK: - child modeling -
extension GridRow {
    /// A child of a `GridRow`.
    public struct Child {
        // MARK: - properties -
        /// The element displayed in the `Grid`.
        public var element: Element
        /// A unique identifier for the child.
        public var key: AnyHashable?
        // The sizing for the element.
        public var width: Width

        // MARK: - initialialization -
        public init(width: Width, key: AnyHashable? = nil, element: Element) {
            self.element = element
            self.key = key
            self.width = width
        }
    }

    /// The sizing and content of a `GridRow` child.
    public enum Width: Equatable {
        /// Assign the child a fixed width equal to the payload.
        case absolute(CGFloat)
        /// Assign the child a proportional width of the available layout width. Note that proportional children
        /// take proportional shares of the available layout width.
        ///
        /// ## Example:
        ///     Available layout width: 100
        ///     Child A: .proportional(1)  -> 25 (100 * 1/4)
        ///     Child B: .proportional(3) -> 75 (100 * 3/4)
        ///
        /// ## Example:
        ///     Available layout width: 100
        ///     Child A: .proportional(0.25)  -> 25 (100 * 1/4)
        ///     Child B: .proportional(0.75) -> 75 (100 * 3/4)
        case proportional(CGFloat)
    }
}

extension Element {
    /// Wraps an element with a `GridRowChild` in order to provide meta information that a `GridRow` can aply to its layout.
    /// - Parameters:
    ///   - key: A unique identifier for the child.
    ///   - width: The sizing for the element.
    /// - Returns: `GridRowChild`
    public func gridRowChild(key: AnyHashable? = nil, width: GridRow.Width) -> GridRow.Child {
        .init(width: width, key: key, element: self)
    }
}

extension GridRow.Child: ElementBuilderChild {
    public init(_ element: Element) {
        self.init(width: .proportional(1), element: element)
    }
}
