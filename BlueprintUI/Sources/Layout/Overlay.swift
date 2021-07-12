import UIKit

/// Stretches all of its child elements to fill the layout area, stacked on top of each other.
///
/// During a layout pass, measurement is calculated as the max size (in both x and y dimensions)
/// produced by measuring all of the child elements.
///
/// View-backed descendants will be z-ordered from back to front in the order of this element's
/// children.
public struct Overlay: Element, ComparableElement {

    /// All elements displayed in the overlay.
    public var elements: [Element]

    /// Creates a new overlay with the provided elements.
    public init(
        elements: [Element] = [],
        configure : (inout Overlay) -> () = { _ in}
    ) {
        self.elements = elements
        configure(&self)
    }
    
    /// Adds the provided element to the overlay.
    public mutating func add(_ element : Element) {
        self.elements.append(element)
    }
    
    // MARK: Element

    public var content: ElementContent {
        return ElementContent(layout: OverlayLayout()) {
            for element in elements {
                $0.add(element: element)
            }
        }
    }

    public func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
        return nil
    }
    
    public func isEquivalent(to other: Overlay) throws -> Bool {
        try self.elements.isEquivalent(to: other.elements)
    }
}

/// A layout implementation that places all children on top of each other with
/// the same frame (filling the container’s bounds).
fileprivate struct OverlayLayout: Layout {

    func measure(
        items: LayoutItems<Void>,
        in constraint : SizeConstraint,
        with context: LayoutContext
    ) -> CGSize
    {
        items.all.reduce(into: CGSize.zero) { result, item in
            let measuredSize = item.content.measure(in: constraint, with: context)
            
            result.width = max(result.width, measuredSize.width)
            result.height = max(result.height, measuredSize.height)
        }
    }

    func layout(
        items: LayoutItems<Void>,
        in size : CGSize,
        with context : LayoutContext
    ) -> [LayoutAttributes]
    {
        Array(
            repeating: LayoutAttributes(size: size),
            count: items.count
        )
    }
}
