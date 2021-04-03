import UIKit
import os.log

/// Represents the content of an element.
public struct ElementContent {

    private let storage: ContentStorage
    
    //
    // MARK: Initialization
    //

    /// Initializes a new `ElementContent` with the given layout and children.
    ///
    /// - parameter layout: The layout to use.
    /// - parameter configure: A closure that configures the layout and adds children to the container.
    public init<LayoutType: Layout>(
        layout: LayoutType,
        configure: (inout Builder<LayoutType>) -> Void = { _ in }
    ) {
        var builder = Builder(layout: layout)
        configure(&builder)
        
        self.storage = builder
    }
    
    // MARK: Measurement & Children

    /// Measures the required size of this element's content.
    /// - Parameters:
    ///   - constraint: The size constraint.
    ///   - environment: The environment to measure in.
    /// - returns: The layout size needed by this content.
    public func measure(in constraint: SizeConstraint, environment: Environment) -> CGSize {
        return measure(
            in: constraint,
            environment: environment,
            cache: CacheFactory.makeCache(name: "ElementContent")
        )
    }

    func measure(in constraint: SizeConstraint, environment: Environment, cache: CacheTree) -> CGSize {
        self.storage.measure(in: constraint, environment: environment, cache: cache)
    }

    public var childCount: Int {
        return storage.childCount
    }

    func performLayout(
        attributes: LayoutAttributes,
        environment: Environment,
        cache: CacheTree
    ) -> [(identifier: ElementIdentifier, node: LayoutResultNode)] {
        return storage.performLayout(
            attributes: attributes,
            environment: environment,
            cache: cache
        )
    }
}

extension ElementContent {
    
    /// Initializes a new `ElementContent` that will lazily create its storage during a layout and measurement pass,
    /// based on the `Environment` passed to the `builder` closure.
    ///
    /// - parameter builder: A closure that provides the content `Element` based on the provided `SizeConstraint`
    ///     and `Environment`.
    public init(
        build builder: @escaping (SizeConstraint, Environment) -> Element
    ) {
        self.storage = LazyStorage(builder: builder)
    }
}

extension ElementContent {

    /// Initializes a new `ElementContent` with the given element and layout.
    ///
    /// - parameter element: The single child element.
    /// - parameter layout: The layout that will be used.
    public init(
        child: Element,
        layout: SingleChildLayout
    ) {
        self = ElementContent(layout: SingleChildLayoutHost(wrapping: layout)) {
            $0.add(element: child)
        }
    }

    /// Initializes a new `ElementContent` with the given element.
    ///
    /// The given element will be used for measuring, and it will always fill the extent of the parent element.
    ///
    /// - parameter element: The single child element.
    public init(
        child: Element
    ) {
        self = ElementContent(child: child, layout: PassthroughLayout())
    }

    /// Initializes a new `ElementContent` with no children that delegates to the provided `Measurable`.
    ///
    /// - parameter measurable: How to measure the `ElementContent`.
    public init(
        measurable: Measurable
    ) {
        self = ElementContent(
            layout: MeasurableLayout(measurable: measurable),
            configure: { _ in }
        )
    }

    /// Initializes a new `ElementContent` with no children that delegates to the provided measure function.
    ///
    /// - parameter measureFunction: How to measure the `ElementContent` in the given `SizeConstraint`.
    public init(
        measureFunction: @escaping (SizeConstraint) -> CGSize
    ) {
        self = ElementContent(measurable: Measurer(_measure: measureFunction))
    }

    /// Initializes a new `ElementContent` with no children that uses the provided intrinsic size for measuring.
    public init(intrinsicSize: CGSize) {
        self = ElementContent(measureFunction: { _ in intrinsicSize })
    }
}

extension ElementContent {
    
    /// Initializes a new `ElementContent` with the given child element, measurement caching key, and environment adapter,
    /// which allows adapting the environment to affect the element, plus elements further down the tree.
    ///
    /// - parameter child: The child element to display.
    /// - parameter environmentAdapter: How to adapt the `Environment` for the child and elements further down the tree.
    public init(
        child: Element,
        environment environmentAdapter: @escaping (inout Environment) -> Void
    ) {        
        self.storage = EnvironmentAdaptingStorage(
            adapter: environmentAdapter,
            child: child
        )
    }

    /// Initializes a new `ElementContent` with the given child element, measurement caching key, and environment key + value.
    /// which adapts the environment to affect the element, plus elements further down the tree.
    ///
    /// - parameter child: The child element to display.
    /// - parameter key: The key to set in the `Environment`.
    /// - parameter value: The value to set in the `Environment` for the given key.
    public init<Key>(
        child: Element,
        key: Key.Type,
        value: Key.Value
    ) where Key: EnvironmentKey {
        
        self.init(child: child) { environment in
            environment[key] = value
        }
    }
}


fileprivate protocol ContentStorage {
    var childCount: Int { get }

    func measure(
        in constraint: SizeConstraint,
        environment: Environment,
        cache: CacheTree
    ) -> CGSize

    func performLayout(
        attributes: LayoutAttributes,
        environment: Environment,
        cache: CacheTree
    ) -> [(identifier: ElementIdentifier, node: LayoutResultNode)]
}


extension ElementContent {

    public struct Builder<LayoutType: Layout> : ContentStorage {

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
        
        // MARK: ContentStorage
        
        var childCount: Int {
            return children.count
        }

        func measure(
            in constraint: SizeConstraint,
            environment: Environment,
            cache: CacheTree
        ) -> CGSize {
            return cache.get(constraint) { (constraint) -> CGSize in
                logMeasureStart(object: cache.signpostRef, description: cache.name, constraint: constraint)
                defer { logMeasureEnd(object: cache.signpostRef) }

                let layoutItems = self.layoutItems(in: environment, cache: cache)
                return layout.measure(in: constraint, items: layoutItems)
            }
        }

        func performLayout(
            attributes: LayoutAttributes,
            environment: Environment,
            cache: CacheTree
        ) -> [(identifier: ElementIdentifier, node: LayoutResultNode)] {
            guard self.children.isEmpty == false else {
                return []
            }
            
            let layoutItems = self.layoutItems(in: environment, cache: cache)
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
                    children: currentChild.content.performLayout(
                        attributes: currentChildLayoutAttributes,
                        environment: environment,
                        cache: cache.subcache(index: index, element: currentChild.element)
                    )
                )

                let identifier = identifierFactory.nextIdentifier(
                    for: type(of: currentChild.element),
                    key: currentChild.key
                )

                result.append((identifier: identifier, node: resultNode))
            }

            return result
        }

        private func layoutItems(
            in environment: Environment,
            cache: CacheTree
        ) -> [(LayoutType.Traits, Measurable)] {

            let isSingleton = children.count == 1

            return zip(children.indices, children).map { index, child in
                let childCache = cache.subcache(
                    key: isSingleton ? .singleton : SubcacheKey(rawValue: index),
                    element: child.element
                )
                let childContent = child.content
                let measurable = Measurer { (constraint) -> CGSize in
                    childContent.measure(
                        in: constraint,
                        environment: environment,
                        cache: childCache
                    )
                }

                return (child.traits, measurable)
            }
        }
        
        fileprivate struct Child {

            var traits: LayoutType.Traits
            var key: AnyHashable?
            var content: ElementContent
            var element: Element

        }
    }
}


private struct EnvironmentAdaptingStorage: ContentStorage {
    let childCount = 1

    /// During measurement or layout, the environment adapter will be applied
    /// to the environment before passing it
    ///
    var adapter: (inout Environment) -> Void

    var child: Element

    func performLayout(
        attributes: LayoutAttributes,
        environment: Environment,
        cache: CacheTree
    ) -> [(identifier: ElementIdentifier, node: LayoutResultNode)] {
        let environment = adapted(environment: environment)

        let childAttributes = LayoutAttributes(size: attributes.bounds.size)

        let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)

        let node = LayoutResultNode(
            element: child,
            layoutAttributes: childAttributes,
            children: child.content.performLayout(
                attributes: childAttributes,
                environment: environment,
                cache: cache.subcache(element: child)
            )
        )

        return [(identifier, node)]
    }

    func measure(in constraint: SizeConstraint, environment: Environment, cache: CacheTree) -> CGSize {
        cache.get(constraint) { (constraint) -> CGSize in
            let environment = adapted(environment: environment)
            return child.content.measure(
                in: constraint,
                environment: environment,
                cache: cache.subcache(element: child)
            )
        }
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

    var builder: (SizeConstraint, Environment) -> Element

    func performLayout(
        attributes: LayoutAttributes,
        environment: Environment,
        cache: CacheTree
    ) -> [(identifier: ElementIdentifier, node: LayoutResultNode)] {
        let constraint = SizeConstraint(attributes.bounds.size)
        let child = buildChild(in: constraint, environment: environment)
        let childAttributes = LayoutAttributes(size: attributes.bounds.size)

        let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)

        let node = LayoutResultNode(
            element: child,
            layoutAttributes: childAttributes,
            children: child.content.performLayout(
                attributes: childAttributes,
                environment: environment,
                cache: cache.subcache(element: child)
            )
        )

        return [(identifier, node)]
    }

    func measure(in constraint: SizeConstraint, environment: Environment, cache: CacheTree) -> CGSize {
        cache.get(constraint) { (constraint) -> CGSize in
            let child = buildChild(in: constraint, environment: environment)
            return child.content.measure(
                in: constraint,
                environment: environment,
                cache: cache.subcache(element: child)
            )
        }
    }

    private func buildChild(in constraint: SizeConstraint, environment: Environment) -> Element {
        return builder(constraint, environment)
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

struct Measurer: Measurable {
    var _measure: (SizeConstraint) -> CGSize
    func measure(in constraint: SizeConstraint) -> CGSize {
        return _measure(constraint)
    }
}

extension ContentStorage {
    func logMeasureStart(object: AnyObject, description: String, constraint: SizeConstraint) {
        if #available(iOS 12.0, *) {
            os_signpost(
                .begin,
                log: .blueprint,
                name: "Measuring",
                signpostID: OSSignpostID(log: .blueprint, object: object),
                // nb: os_signpost seems to ignore precision specifiers
                "%{public}s in %.1f×%.1f",
                description,
                constraint.width.constrainedValue ?? .infinity,
                constraint.height.constrainedValue ?? .infinity
            )
        }
    }

    func logMeasureEnd(object: AnyObject) {
        if #available(iOS 12.0, *) {
            os_signpost(
                .end,
                log: .blueprint,
                name: "Measuring",
                signpostID: OSSignpostID(log: .blueprint, object: object)
            )
        }
    }
}
