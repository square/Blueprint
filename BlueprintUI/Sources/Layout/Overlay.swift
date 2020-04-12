import UIKit

/// Stretches all of its child elements to fill the layout area, stacked on top of each other.
///
/// During a layout pass, measurent is calculated as the max size (in both x and y dimensions)
/// produced by measuring all of the child elements.
///
/// View-backed descendents will be z-ordered from back to front in the order of this element's
/// children.
public struct Overlay: Element {

    public var elements: [Element]

    public init(elements: [Element]) {
        self.elements = elements
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
    
    func layout(in constraint : SizeConstraint, items: [LayoutItem<Self>]) -> LayoutResult {
        LayoutResult(
            size: {
                items.reduce(into: CGSize.zero, { result, item in
                    let measuredSize = item.content.size(in: constraint)
                    
                    result.width = max(result.width, measuredSize.width)
                    result.height = max(result.height, measuredSize.height)
                })
            },
            layoutAttributes: {
                Array(
                    repeating: LayoutAttributes(size: $0),
                    count: items.count
                )
            }
        )
    }
}
