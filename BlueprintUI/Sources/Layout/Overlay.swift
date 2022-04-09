import UIKit

/// Stretches all of its child elements to fill the layout area, stacked on top of each other.
///
/// During a layout pass, measurement is calculated as the max size (in both x and y dimensions)
/// produced by measuring all of the child elements.
///
/// View-backed descendants will be z-ordered from back to front in the order of this element's
/// children.
public struct Overlay: Element {

    /// All elements displayed in the overlay.
    public var children: [Child]

    /// Creates a new overlay with the provided elements.
    public init(
        elements: [Element] = [],
        configure: (inout Overlay) -> Void = { _ in }
    ) {
        children = elements.map { Child(element: $0) }
        configure(&self)
    }

    /// Creates a new overlay using a result builder.
    public init(
        @ElementBuilder<Overlay.Child> elements: () -> [Overlay.Child]
    ) {
        children = elements()
    }

    /// Adds the provided element to the overlay.
    @available(*, deprecated, renamed: "add(child:)")
    public mutating func add(_ element: Element) {
        children.append(Child(element: element))
    }

    /// Adds the provided element to the overlay, above other children.
    ///
    /// - Parameters:
    ///   - key: A key used to disambiguate children between subsequent updates of the view
    ///     hierarchy
    ///   - child: The child element to add.
    public mutating func add(key: AnyHashable? = nil, child: Element) {
        children.append(Child(element: child, key: key))
    }

    // MARK: Element

    public var content: ElementContent {
        ElementContent(layout: OverlayLayout()) { builder in
            for child in children {
                builder.add(key: child.key, element: child.element)
            }
        }
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        nil
    }
}

/// A layout implementation that places all children on top of each other with
/// the same frame (filling the container’s bounds).
fileprivate struct OverlayLayout: Layout {

    func measure(in constraint: SizeConstraint, items: [(traits: Void, content: Measurable)]) -> CGSize {
        items.reduce(into: CGSize.zero) { result, item in
            let measuredSize = item.content.measure(in: constraint)
            result.width = max(result.width, measuredSize.width)
            result.height = max(result.height, measuredSize.height)
        }
    }

    func layout(size: CGSize, items: [(traits: Void, content: Measurable)]) -> [LayoutAttributes] {
        Array(
            repeating: LayoutAttributes(size: size),
            count: items.count
        )
    }

}

extension Overlay {
    /// The child of an `Overlay`.
    public struct Child {
        /// The child element
        public var element: Element
        /// An optional key to disambiguate between view updates
        public var key: AnyHashable?

        /// Create a new child.
        public init(element: Element, key: AnyHashable? = nil) {
            self.element = element
            self.key = key
        }
    }
}

extension Overlay.Child: ElementBuilderChild {
    public init(_ element: Element) {
        self.init(element: element, key: nil)
    }
}

/// Map `Keyed` elements in result builders to `Overlay.Child`.
extension ElementBuilder where Child == Overlay.Child {
    public static func buildExpression(_ keyed: Keyed) -> Children {
        [Overlay.Child(element: keyed.wrapped, key: keyed.key)]
    }
}

extension Element {
    public func overlayChild(key: AnyHashable? = nil) -> Overlay.Child {
        .init(element: self, key: key)
    }
}
