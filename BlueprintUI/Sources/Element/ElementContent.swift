import UIKit

/// Represents the content of an element.
public struct ElementContent: Measurable {

    private let storage: ContentStorage

    /// Initializes a new `ElementContent` with the given layout and children.
    ///
    /// - parameter layout: The layout to use.
    /// - parameter configure: A closure that configures the layout and adds children to the container.
    public init<LayoutType: Layout>(layout: LayoutType, configure: (inout Builder<LayoutType>) -> Void = { _ in }) {
        var builder = Builder(layout: layout)
        configure(&builder)
        self.storage = builder
    }

    public func measure(in constraint: SizeConstraint) -> CGSize {
        return storage.measure(in: constraint)
    }

    public var childCount: Int {
        return storage.childCount
    }

    func performLayout(attributes: LayoutAttributes) -> [(identifier: ElementIdentifier, node: LayoutResultNode)] {
        return storage.performLayout(attributes: attributes)
    }

}

extension ElementContent {

    /// Initializes a new `ElementContent` with the given element and layout.
    ///
    /// - parameter element: The single child element.
    /// - parameter layout: The layout that will be used.
    public init(child: Element, layout: SingleChildLayout) {
        self = ElementContent(layout: SingleChildLayoutHost(wrapping: layout)) {
            $0.add(element: child)
        }
    }

    /// Initializes a new `ElementContent` with the given element.
    ///
    /// The given element will be used for measuring, and it will always fill the extent of the parent element.
    ///
    /// - parameter element: The single child element.
    public init(child: Element) {
        self = ElementContent(child: child, layout: PassthroughLayout())
    }

    /// Initializes a new `ElementContent` with no children that delegates to the provided `Measurable`.
    public init(measurable: Measurable) {
        self = ElementContent(
            layout: MeasurableLayout(measurable: measurable),
            configure: { _ in })
    }

    /// Initializes a new `ElementContent` with no children that delegates to the provided measure function.
    public init(measureFunction: @escaping (SizeConstraint) -> CGSize) {
        struct Measurer: Measurable {
            var _measure: (SizeConstraint) -> CGSize
            func measure(in constraint: SizeConstraint) -> CGSize {
                return _measure(constraint)
            }
        }
        self = ElementContent(measurable: Measurer(_measure: measureFunction))
    }

    /// Initializes a new `ElementContent` with no children that uses the provided intrinsic size for measuring.
    public init(intrinsicSize: CGSize) {
        self = ElementContent(measureFunction: { _ in intrinsicSize })
    }

}


fileprivate protocol ContentStorage: Measurable {
    var childCount: Int { get }
    func performLayout(attributes: LayoutAttributes) -> [(identifier: ElementIdentifier, node: LayoutResultNode)]
}




extension ElementContent {

    public struct Builder<LayoutType: Layout> {

        /// The layout object that is ultimately responsible for measuring
        /// and layout tasks.
        public var layout: LayoutType

        /// Child elements.
        fileprivate var children: [Child] = []

        init(layout: LayoutType) {
            self.layout = layout
        }

    }


}

extension ElementContent.Builder {

    /// Adds the given child element.
    public mutating func add(traits: LayoutType.Traits = LayoutType.defaultTraits, key: AnyHashable? = nil, element: Element) {
        let child = Child(
            traits: traits,
            key: key,
            content: element.content,
            element: element)
        children.append(child)
    }

}

extension ElementContent.Builder: ContentStorage {

    var childCount: Int {
        return children.count
    }

    public func measure(in constraint: SizeConstraint) -> CGSize {
        return layout.measure(in: constraint, items: layoutItems)
    }

    func performLayout(attributes: LayoutAttributes) -> [(identifier: ElementIdentifier, node: LayoutResultNode)] {

        let childAttributes = layout.layout(size: attributes.bounds.size, items: layoutItems)

        var result: [(identifier: ElementIdentifier, node: LayoutResultNode)] = []
        result.reserveCapacity(children.count)
        
        var identifierFactory = ElementIdentifier.Factory(reserveCapacity: children.count)

        for index in 0..<children.count {
            let currentChildLayoutAttributes = childAttributes[index]
            let currentChild = children[index]

            let resultNode = LayoutResultNode(
                element: currentChild.element,
                layoutAttributes: currentChildLayoutAttributes,
                content: currentChild.content
            )
            
            let identifier = identifierFactory.nextIdentifier(
                for: type(of: currentChild.element),
                key: currentChild.key
            )

            result.append((identifier: identifier, node: resultNode))
        }

        return result
    }

    private var layoutItems: [(LayoutType.Traits, Measurable)] {
        return children.map { ($0.traits, $0) }
    }

}


extension ElementContent.Builder {

    fileprivate struct Child: Measurable {

        var traits: LayoutType.Traits
        var key: AnyHashable?
        var content: ElementContent
        var element: Element

        func measure(in constraint: SizeConstraint) -> CGSize {
            return content.measure(in: constraint)
        }

    }

}

// All layout is ultimately performed by the `Layout` protocol – this implementations delegates to a wrapped
// `SingleChildLayout` implementation for use in elements with a single child.
fileprivate struct SingleChildLayoutHost: Layout {

    private var wrapped: SingleChildLayout

    init(wrapping layout: SingleChildLayout) {
        self.wrapped = layout
    }

    func measure(in constraint: SizeConstraint, items: [(traits: (), content: Measurable)]) -> CGSize {
        precondition(items.count == 1)
        return wrapped.measure(in: constraint, child: items.map { $0.content }.first!)
    }

    func layout(size: CGSize, items: [(traits: (), content: Measurable)]) -> [LayoutAttributes] {
        precondition(items.count == 1)
        return [
            wrapped.layout(size: size, child: items.map { $0.content }.first!)
        ]
    }
}

// Used for elements with a single child that requires no custom layout
fileprivate struct PassthroughLayout: SingleChildLayout {

    func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {
        return child.measure(in: constraint)
    }

    func layout(size: CGSize, child: Measurable) -> LayoutAttributes {
        return LayoutAttributes(size: size)
    }

}

// Used for empty elements with an intrinsic size
fileprivate struct MeasurableLayout: Layout {

    var measurable: Measurable

    func measure(in constraint: SizeConstraint, items: [(traits: (), content: Measurable)]) -> CGSize {
        precondition(items.isEmpty)
        return measurable.measure(in: constraint)
    }

    func layout(size: CGSize, items: [(traits: (), content: Measurable)]) -> [LayoutAttributes] {
        precondition(items.isEmpty)
        return []
    }

}
