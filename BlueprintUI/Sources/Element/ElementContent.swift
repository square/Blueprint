import UIKit

/// Represents the content of an element.
public struct ElementContent {

    private let storage: AnyContentStorage

    /// Initializes a new `ElementContent` with the given layout and children.
    ///
    /// - parameter layout: The layout to use.
    /// - parameter configure: A closure that configures the layout and adds children to the container.
    public init<LayoutType: Layout>(layout: LayoutType, configure: (inout ContentStorage<LayoutType>) -> Void = { _ in }) {
        var storage = ContentStorage(layout: layout)
        configure(&storage)
        self.storage = storage
    }

    public var childCount: Int {
        storage.childCount
    }
    
    public func layout(in constraint : SizeConstraint) -> LayoutResult {
        storage.layout(in: constraint)
    }
    
    public func size(in constraint : SizeConstraint) -> CGSize {
        layout(in: constraint).size
    }

    func layoutElementTree(attributes: LayoutAttributes) -> [(identifier: ElementIdentifier, node: LayoutResultNode)] {
        storage.layoutElementTree(attributes: attributes)
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
    
    /// Initializes a new `ElementContent` with no children that delegates to the provided closure.
    public init(measure: @escaping (SizeConstraint) -> CGSize) {
        self = ElementContent(
            layout: IntrinsicSizeLayout(measure: measure),
            configure: { _ in }
        )
    }

    /// Initializes a new `ElementContent` with no children that uses the provided intrinsic size for measuring.
    public init(intrinsicSize: CGSize) {
        self = ElementContent(measure: { _ in intrinsicSize })
    }
}


fileprivate protocol AnyContentStorage {
    var childCount: Int { get }
    func layout(in constraint : SizeConstraint) -> LayoutResult
    func layoutElementTree(attributes: LayoutAttributes) -> [(identifier: ElementIdentifier, node: LayoutResultNode)]
}


extension ElementContent {

    public struct ContentStorage<LayoutType: Layout> : AnyContentStorage {

        /// The layout object that is ultimately responsible for measuring
        /// and layout tasks.
        public var layout: LayoutType

        /// Child elements.
        fileprivate var children: [Child] = []

        init(layout: LayoutType) {
            self.layout = layout
        }
        
        /// Adds the given child element.
        public mutating func add(element: Element, traits: LayoutType.Traits = LayoutType.defaultTraits, key: AnyHashable? = nil) {
            self.add(Child(
                element: element,
                content: element.content,
                traits: traits,
                key: key
            ))
        }
        
        public mutating func add(_ child : Child) {
            self.children.append(child)
        }
        
        public mutating func add(_ children : [Child]) {
            self.children += children
        }
        
        public struct Child {
            public var element: Element
            public var content: ElementContent
            public var traits: LayoutType.Traits
            public var key: AnyHashable?
        }
        
        public func measure(in constraint: SizeConstraint) -> CGSize {
            return layout(in: constraint).size
        }
        
        // MARK: AnyContentStorage
        
        var childCount: Int {
            return children.count
        }
        
        func layout(in constraint : SizeConstraint) -> LayoutResult {
            self.layout.layout(in: constraint, items: self.children.map {
                LayoutItem(element: $0.element, content: $0.content, traits: $0.traits, key: $0.key)
            })
        }

        func layoutElementTree(attributes: LayoutAttributes) -> [(identifier: ElementIdentifier, node: LayoutResultNode)] {

            let childAttributes = layout.layout(in: SizeConstraint(attributes.bounds.size), items: self.layoutItems)
            
            var identifierFactory = ElementIdentifier.Factory(elementCount: children.count)
            
            return self.children.mapWithIndex { index, _, child in
                let childLayoutAttributes = childAttributes.layoutAttributes[index]

                let resultNode = LayoutResultNode(
                    element: child.element,
                    layoutAttributes: childLayoutAttributes,
                    content: child.content
                )
                
                let identifier = identifierFactory.nextIdentifier(
                    for: type(of: child.element),
                    key: child.key
                )

                return (identifier: identifier, node: resultNode)
            }
        }

        private var layoutItems: [LayoutItem<LayoutType>] {
            children.map {
                LayoutItem(
                    element: $0.element,
                    content: $0.content,
                    traits: $0.traits,
                    key: $0.key
                )
            }
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
    
    func layout(in constraint : SizeConstraint, items: [LayoutItem<Self>]) -> LayoutResult {
        precondition(items.count == 1)
        
        let item = items[0]
                
        let result = wrapped.layout(
            in: constraint,
            child: MeasurableChild {
                item.content.size(in: $0)
            }
        )
                
        return LayoutResult(
            size: result.size,
            layoutAttributes: [result.layoutAttributes]
        )
    }
}

// Used for elements with a single child that requires no custom layout
fileprivate struct PassthroughLayout: SingleChildLayout {
    
    func layout(in constraint : SizeConstraint, child : MeasurableChild) -> SingleChildLayoutResult {
        SingleChildLayoutResult(
            size: { child.size(in: constraint) },
            layoutAttributes: { LayoutAttributes(size: $0) }
        )
    }
}

// Used for empty elements with an intrinsic size
fileprivate struct IntrinsicSizeLayout: Layout {

    // TODO: This, or a layout?
    var measure : (SizeConstraint) -> CGSize
    
    public func layout(in constraint : SizeConstraint, items: [LayoutItem<Self>]) -> LayoutResult {
        precondition(items.isEmpty)

        return LayoutResult(
            size: measure(constraint),
            layoutAttributes: []
        )
    }
}

fileprivate extension Array {
    func mapWithIndex<Mapped>(_ block : (Int, Bool, Element) -> Mapped) -> [Mapped]
    {
        var mapped = [Mapped]()
        mapped.reserveCapacity(self.count)
        
        let count = self.count
        var index : Int = 0
        
        while index < count {
            let element = self[index]
            mapped.append(block(index, index == (count - 1), element))
            index += 1
        }
        
        return mapped
    }
}
