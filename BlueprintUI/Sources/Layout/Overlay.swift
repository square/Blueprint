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

    func measure(in constraint: SizeConstraint, items: [(traits: Void, content: Measurable)]) -> CGSize {
        return items.reduce(into: CGSize.zero, { (result, item) in
            let measuredSize = item.content.measure(in: constraint)
            result.width = max(result.width, measuredSize.width)
            result.height = max(result.height, measuredSize.height)
        })
    }

    func layout(size: CGSize, items: [(traits: Void, content: Measurable)]) -> [LayoutAttributes] {
        return Array(
            repeating: LayoutAttributes(size: size),
            count: items.count)
    }

}
