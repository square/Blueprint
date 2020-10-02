import UIKit

/// Stretches all of its child elements to fill the layout area, stacked on top of each other.
///
/// During a layout pass, measurent is calculated as the max size (in both x and y dimensions)
/// produced by measuring all of the child elements.
///
/// View-backed descendents will be z-ordered from back to front in the order of this element's
/// children.
public struct Overlay: Element {

    /// The elements that are overlayed on top of each other to form the overlay.
    ///
    /// The elements are ordered back to front; the first item in the array
    /// is at the bottom of the overlay, and the last item in the array is at the top.
    public var elements: [Element]

    /// Creates a new overlay with the provided elements.
    public init(elements: [Element]) {
        self.elements = elements
    }
    
    /// Creates a new overlay that is configured with the provided closure.
    /// ```
    /// Overlay { overlay in
    ///     overlay.add {
    ///         Label(text: ...)
    ///         .inset(uniform: 10)
    ///         ...
    ///     }
    /// }
    /// ```
    public init(_ configure : (inout Self) -> ()) {
        self.elements = []
        
        configure(&self)
    }
    
    /// Adds the provided element to the overlay, as the new top item.
    public mutating func add(_ element : Element) {
        self.elements.append(element)
    }
    
    /// Adds the provided element to the overlay, as the new top item.
    /// 
    /// ```
    /// overlay.add {
    ///     Label(text: ...)
    ///         .inset(uniform: 10)
    ///         ...
    /// }
    /// ```
    public mutating func add(_ element : () -> Element) {
        self.elements.append(element())
    }

    public var content: ElementContent {
        return ElementContent(layout: OverlayLayout()) {
            for element in elements {
                $0.add(element: element)
            }
        }
    }

    public func backingViewDescription(bounds: CGRect, subtreeExtent: CGRect?) -> ViewDescription? {
        return nil
    }
}

/// A layout implementation that places all children on top of each other with
/// the same frame (filling the container’s bounds).
fileprivate struct OverlayLayout: Layout {

    func measure(in constraint: SizeConstraint, items: [(traits: Void, content: Measurable)]) -> CGSize {
        items.reduce(into: CGSize.zero, { result, item in
            let measuredSize = item.content.measure(in: constraint)
            result.width = max(result.width, measuredSize.width)
            result.height = max(result.height, measuredSize.height)
        })
    }

    func layout(size: CGSize, items: [(traits: Void, content: Measurable)]) -> [LayoutAttributes] {
        Array(
            repeating: LayoutAttributes(size: size),
            count: items.count
        )
    }

}
