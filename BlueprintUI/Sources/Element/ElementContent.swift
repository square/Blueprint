import UIKit

/// Represents the content of an element.
public struct ElementContent {

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

    /// Measures the required size of this element's content.
    /// - Parameters:
    ///   - constraint: The size constraint.
    ///   - environment: The environment to measure in.
    /// - returns: The layout size needed by this content.
    public func measure(in constraint: SizeConstraint, environment: Environment) -> CGSize {
        return storage.measure(in: constraint, environment: environment)
    }

    public var childCount: Int {
        return storage.childCount
    }

    func performLayout(attributes: LayoutAttributes, environment: Environment) -> [(identifier: ElementIdentifier, node: LayoutResultNode)] {
        return storage.performLayout(attributes: attributes, environment: environment)
    }
    
    func children(in environment: Environment) -> [AnyElementContentChild]
    {
        self.storage.children(in: environment)
    }
}

extension ElementContent {
    fileprivate func measurable(in environment: Environment) -> Measurable {
        struct EnvironmentMeasurable: Measurable {
            var environment: Environment
            var content: ElementContent

            func measure(in constraint: SizeConstraint) -> CGSize {
                return content.measure(in: constraint, environment: environment)
            }
        }

        return EnvironmentMeasurable(environment: environment, content: self)
    }
}

extension ElementContent {
    public init(build builder: @escaping (Environment) -> Element) {
        self.storage = LazyStorage(builder: builder)
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

extension ElementContent {
    public init(child: Element, environment environmentAdapter: @escaping (inout Environment) -> Void) {
        self.storage = EnvironmentAdaptingStorage(
            adapter: environmentAdapter,
            child: child)
    }

    public init<Key>(child: Element, key: Key.Type, value: Key.Value) where Key: EnvironmentKey {
        self.init(child: child) { environment in
            environment[key] = value
        }
    }
}


public protocol AnyElementContentChild {

    var element: Element { get }
    
    var key: AnyHashable? { get }
}


fileprivate protocol ContentStorage {
    var childCount: Int { get }
    
    func children(in environment : Environment) -> [AnyElementContentChild]

    func measure(in constraint: SizeConstraint, environment: Environment) -> CGSize

    func performLayout(
        attributes: LayoutAttributes,
        environment: Environment
    ) -> [(identifier: ElementIdentifier, node: LayoutResultNode)]
}


final class LiveElementStorage<LayoutType: Layout> : ContentStorage {

    let live : LiveElementState
    let layout : LayoutType
    
    init(_ live : LiveElementState, layout : LayoutType) {
        self.live = live
        self.layout = layout
    }
    
    var childCount: Int {
        self.live.children.count
    }
    
    func children(in environment: Environment) -> [AnyElementContentChild] {
        fatalError()
    }
    
    func measure(in constraint: SizeConstraint, environment: Environment) -> CGSize {
        let layoutItems = self.layoutItems(in: environment)
        return layout.measure(in: constraint, items: layoutItems)
    }
    
    func performLayout(attributes: LayoutAttributes, environment: Environment) -> [(identifier: ElementIdentifier, node: LayoutResultNode)] {
        
        let children = self.live.children
        
        let layoutItems = self.layoutItems(in: environment)
        let childAttributes = layout.layout(size: attributes.bounds.size, items: layoutItems)

        var result: [(identifier: ElementIdentifier, node: LayoutResultNode)] = []
        result.reserveCapacity(children.count)
        
        var identifierFactory = ElementIdentifier.Factory(elementCount: children.count)

        for index in 0..<children.count {
            let currentChildLayoutAttributes = childAttributes[index]
            let currentChild = children[index]

            let resultNode = LayoutResultNode(
                element: currentChild.element,
                layoutAttributes: currentChildLayoutAttributes,
                content: currentChild.elementContent,
                environment: environment
            )

            let identifier = identifierFactory.nextIdentifier(
                for: type(of: currentChild.element),
                key: currentChild.key
            )

            result.append((identifier: identifier, node: resultNode))
        }

        return result
    }
    
    private func layoutItems(in environment: Environment) -> [(LayoutType.Traits, Measurable)] {
        return self.live.children.map { ($0.traits, $0.content.measurable(in: environment)) }
    }
}


extension ElementContent {

    public struct Builder<LayoutType: Layout> : ContentStorage {
        
        func toLiveElementStorage(with live : LiveElementState) -> LiveElementStorage<LayoutType>
        {
            LiveElementStorage(live, layout: self.layout)
        }

        /// The layout object that is ultimately responsible for measuring
        /// and layout tasks.
        public var layout: LayoutType

        /// Child elements.
        fileprivate var children: [Child] = []

        init(layout: LayoutType) {
            self.layout = layout
        }
        
        /// Adds the given child element.
        public mutating func add(traits: LayoutType.Traits = LayoutType.defaultTraits, key: AnyHashable? = nil, element: Element) {
            let child = Child(
                traits: traits,
                key: key,
                content: element.content,
                element: element
            )
            
            children.append(child)
        }
        
        fileprivate struct Child : AnyElementContentChild {

            var traits: LayoutType.Traits
            var key: AnyHashable?
            var content: ElementContent
            var element: Element

        }
        
        // MARK: ContentStorage
        
        var childCount: Int {
            return children.count
        }
        
        func children(in environment : Environment) -> [AnyElementContentChild]
        {
            return self.children
        }

        func measure(in constraint: SizeConstraint, environment: Environment) -> CGSize {
            let layoutItems = self.layoutItems(in: environment)
            return layout.measure(in: constraint, items: layoutItems)
        }

        func performLayout(
            attributes: LayoutAttributes,
            environment: Environment)
            -> [(identifier: ElementIdentifier, node: LayoutResultNode)]
        {
            let layoutItems = self.layoutItems(in: environment)
            let childAttributes = layout.layout(size: attributes.bounds.size, items: layoutItems)

            var result: [(identifier: ElementIdentifier, node: LayoutResultNode)] = []
            result.reserveCapacity(children.count)
            
            var identifierFactory = ElementIdentifier.Factory(elementCount: children.count)

            for index in 0..<children.count {
                let currentChildLayoutAttributes = childAttributes[index]
                let currentChild = children[index]

                let resultNode = LayoutResultNode(
                    element: currentChild.element,
                    layoutAttributes: currentChildLayoutAttributes,
                    content: currentChild.content,
                    environment: environment
                )

                let identifier = identifierFactory.nextIdentifier(
                    for: type(of: currentChild.element),
                    key: currentChild.key
                )

                result.append((identifier: identifier, node: resultNode))
            }

            return result
        }

        private func layoutItems(in environment: Environment) -> [(LayoutType.Traits, Measurable)] {
            return children.map { ($0.traits, $0.content.measurable(in: environment)) }
        }
    }
}


private struct EnvironmentAdaptingStorage: ContentStorage {
    let childCount = 1
    
    func children(in environment: Environment) -> [AnyElementContentChild] {
        [Child(element: self.child)]
    }
    
    private struct Child : AnyElementContentChild {
        let key: AnyHashable? = nil
        
        var element: Element
    }

    /// During measurement or layout, the environment adapter will be applied
    /// to the environment before passing it
    ///
    var adapter: (inout Environment) -> Void

    var child: Element

    func performLayout(
        attributes: LayoutAttributes,
        environment: Environment)
        -> [(identifier: ElementIdentifier, node: LayoutResultNode)]
    {
        let environment = adapted(environment: environment)

        let childAttributes = LayoutAttributes(size: attributes.bounds.size)

        let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)

        let node = LayoutResultNode(
            element: child,
            layoutAttributes: childAttributes,
            content: child.content,
            environment: environment)

        return [(identifier, node)]
    }

    func measure(in constraint: SizeConstraint, environment: Environment) -> CGSize {
        let environment = adapted(environment: environment)

        return child.content.measure(in: constraint, environment: environment)
    }

    private func adapted(environment: Environment) -> Environment {
        var environment = environment
        adapter(&environment)
        return environment
    }
}

/// Content storage that defers creation of its child until measurement or layout time.
private struct LazyStorage: ContentStorage {
    let childCount = 1
    
    func children(in environment: Environment) -> [AnyElementContentChild] {
        [Child(element: self.builder(environment))]
    }
    
    struct Child : AnyElementContentChild {
        let key: AnyHashable? = nil
        
        var element: Element
    }

    var builder: (Environment) -> Element

    func performLayout(
        attributes: LayoutAttributes,
        environment: Environment)
        -> [(identifier: ElementIdentifier, node: LayoutResultNode)]
    {
        let child = buildChild(in: environment)
        let childAttributes = LayoutAttributes(size: attributes.bounds.size)

        let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)

        let node = LayoutResultNode(
            element: child,
            layoutAttributes: childAttributes,
            content: child.content,
            environment: environment)

        return [(identifier, node)]
    }

    func measure(in constraint: SizeConstraint, environment: Environment) -> CGSize {
        let child = buildChild(in: environment)
        return child.content.measure(in: constraint, environment: environment)
    }

    private func buildChild(in environment: Environment) -> Element {
        return builder(environment)
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
