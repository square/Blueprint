import UIKit

/// Represents the content of an element.
public struct ElementContent {

    private let storage: ContentStorage

    /// The key to use to cache measurement values.
    private let measurementCachingKey: MeasurementCachingKey?

    //
    // MARK: Initialization
    //

    /// Initializes a new `ElementContent` with the given layout and children.
    ///
    /// - parameter layout: The layout to use.
    /// - parameter measurementCachingKey: An optional key to use to cache measurement. See the `MeasurementCachingKey` documentation for more.
    /// - parameter configure: A closure that configures the layout and adds children to the container.
    public init<LayoutType: Layout & SPLayout>(
        layout: LayoutType,
        measurementCachingKey: MeasurementCachingKey? = nil,
        configure: (inout Builder<LayoutType>) -> Void = { _ in }
    ) {
        var builder = Builder(layout: layout)
        configure(&builder)

        storage = builder
        self.measurementCachingKey = measurementCachingKey
    }

    // MARK: Measurement & Children

    /// Measures the required size of this element's content.
    /// - Parameters:
    ///   - constraint: The size constraint.
    ///   - environment: The environment to measure in.
    /// - returns: The layout size needed by this content.
    public func measure(in constraint: SizeConstraint, environment: Environment) -> CGSize {
        measure(
            in: constraint,
            environment: environment,
            cache: CacheFactory.makeCache(name: "ElementContent")
        )
    }

    func measure(
        in constraint: SizeConstraint,
        environment: Environment,
        cache: CacheTree,
        singlePass: Bool
    ) -> CGSize {
        if singlePass {
            return singlePassLayout(
                in: SPLayoutContext(
                    proposedSize: constraint.singlePassSize,
                    mode: AxisVarying(horizontal: .natural, vertical: .natural)
                ),
                environment: environment,
                cache: cache
            )
            .intermediate
            .size
        } else {
            return measure(in: constraint, environment: environment, cache: cache)
        }
    }

    func measure(in constraint: SizeConstraint, environment: Environment, cache: CacheTree) -> CGSize {
        environment.measurementCache.measurement(with: measurementCachingKey, in: constraint) {
            self.storage.measure(in: constraint, environment: environment, cache: cache)
        }
    }

    public var childCount: Int {
        storage.childCount
    }

    func performLayout(
        attributes: LayoutAttributes,
        environment: Environment,
        cache: CacheTree
    ) -> [(identifier: ElementIdentifier, node: LayoutResultNode)] {
        storage.performLayout(
            attributes: attributes,
            environment: environment,
            cache: cache
        )
    }

    func singlePassLayout(
        in context: SPLayoutContext,
        environment: Environment,
        cache: CacheTree
    ) -> SPSubtreeResult {
        storage.singlePassLayout(in: context, environment: environment, cache: cache)
    }
}

extension ElementContent {

    /// Initializes a new `ElementContent` that will lazily create its storage during a layout and measurement pass,
    /// based on the `Environment` passed to the `builder` closure.
    ///
    /// - parameter measurementCachingKey: An optional key to use to cache measurement. See the `MeasurementCachingKey`
    ///     documentation for more.
    /// - parameter builder: A closure that provides the content `Element` based on the provided `SizeConstraint`
    ///     and `Environment`.
    public init(
        measurementCachingKey: MeasurementCachingKey? = nil,
        build builder: @escaping (SizeConstraint, Environment) -> Element
    ) {
        self.measurementCachingKey = measurementCachingKey
        storage = LazyStorage(builder: builder)
    }
}

extension ElementContent {

    /// Initializes a new `ElementContent` with the given element and layout.
    ///
    /// - parameter element: The single child element.
    /// - parameter key: The key to use to unique the element during updates.
    /// - parameter layout: The layout that will be used.
    /// - parameter measurementCachingKey: An optional key to use to cache measurement. See the `MeasurementCachingKey` documentation for more.
    public init(
        child: Element,
        key: AnyHashable? = nil,
        layout: SingleChildLayout & SPSingleChildLayout,
        measurementCachingKey: MeasurementCachingKey? = nil
    ) {
        self = ElementContent(
            layout: SingleChildLayoutHost(wrapping: layout),
            measurementCachingKey: measurementCachingKey
        ) {
            $0.add(key: key, element: child)
        }
    }

    /// Initializes a new `ElementContent` with the given element.
    ///
    /// The given element will be used for measuring, and it will always fill the extent of the parent element.
    ///
    /// - parameter element: The single child element.
    /// - parameter measurementCachingKey: An optional key to use to cache measurement. See the `MeasurementCachingKey` documentation for more.
    public init(
        child: Element,
        measurementCachingKey: MeasurementCachingKey? = nil
    ) {
        self = ElementContent(child: child, layout: PassthroughLayout(), measurementCachingKey: measurementCachingKey)
    }

    /// Initializes a new `ElementContent` with no children that delegates to the provided `Measurable`.
    ///
    /// - parameter measurable: How to measure the `ElementContent`.
    /// - parameter measurementCachingKey: An optional key to use to cache measurement. See the `MeasurementCachingKey` documentation for more.
    public init(
        measurable: Measurable,
        measurementCachingKey: MeasurementCachingKey? = nil
    ) {
        self = ElementContent(
            layout: MeasurableLayout(measurable: measurable),
            measurementCachingKey: measurementCachingKey,
            configure: { _ in }
        )
    }

    /// Initializes a new `ElementContent` with no children that delegates to the provided measure function.
    ///
    /// - parameter measurementCachingKey: An optional key to use to cache measurement. See the `MeasurementCachingKey` documentation for more.
    /// - parameter measureFunction: How to measure the `ElementContent` in the given `SizeConstraint`.
    public init(
        measurementCachingKey: MeasurementCachingKey? = nil,
        measureFunction: @escaping (SizeConstraint) -> CGSize
    ) {
        self = ElementContent(measurementCachingKey: measurementCachingKey) { constraint, _ in
            measureFunction(constraint)
        }
    }

    /// Initializes a new `ElementContent` with no children that delegates to the provided measure function.
    ///
    /// - parameter measurementCachingKey: An optional key to use to cache measurement. See the `MeasurementCachingKey` documentation for more.
    /// - parameter measureFunction: How to measure the `ElementContent` in the given `SizeConstraint` and `Environment`.
    public init(
        measurementCachingKey: MeasurementCachingKey? = nil,
        measureFunction: @escaping (SizeConstraint, Environment) -> CGSize
    ) {
        self.measurementCachingKey = measurementCachingKey
        storage = MeasurableStorage(measurer: measureFunction)
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
    /// - parameter measurementCachingKey: An optional key to use to cache measurement. See the `MeasurementCachingKey` documentation for more.
    /// - parameter environmentAdapter: How to adapt the `Environment` for the child and elements further down the tree.
    public init(
        child: Element,
        measurementCachingKey: MeasurementCachingKey? = nil,
        environment environmentAdapter: @escaping (inout Environment) -> Void
    ) {
        self.measurementCachingKey = measurementCachingKey

        storage = EnvironmentAdaptingStorage(
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
    /// - parameter measurementCachingKey: An optional key to use to cache measurement. See the `MeasurementCachingKey` documentation for more.
    public init<Key>(
        child: Element,
        key: Key.Type,
        value: Key.Value,
        measurementCachingKey: MeasurementCachingKey? = nil
    ) where Key: EnvironmentKey {

        self.init(child: child, measurementCachingKey: measurementCachingKey) { environment in
            environment[key] = value
        }
    }
}


protocol ContentStorage {
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

    func singlePassLayout(
        in context: SPLayoutContext,
        environment: Environment,
        cache: CacheTree
    ) -> SPSubtreeResult

//    func children(in context: LayoutContext) -> [Element]
}


extension ElementContent {

    public struct Builder<LayoutType: Layout & SPLayout>: ContentStorage {

        /// The layout object that is ultimately responsible for measuring
        /// and layout tasks.
        public var layout: LayoutType

        /// Child elements.
        var children: [Child] = []

        init(layout: LayoutType) {
            self.layout = layout
        }

        /// Adds the given child element.
        public mutating func add(
            traits: LayoutType.Traits = LayoutType.defaultTraits,
            key: AnyHashable? = nil,
            element: Element
        ) {
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
            children.count
        }

        func measure(
            in constraint: SizeConstraint,
            environment: Environment,
            cache: CacheTree
        ) -> CGSize {
            cache.get(constraint) { constraint -> CGSize in
                Logger.logMeasureStart(
                    object: cache.signpostRef,
                    description: cache.name,
                    constraint: constraint
                )
                defer { Logger.logMeasureEnd(object: cache.signpostRef) }

                let layoutItems = self.layoutItems(in: environment, cache: cache)
                return layout.measure(in: constraint, items: layoutItems)
            }
        }

        func performLayout(
            attributes: LayoutAttributes,
            environment: Environment,
            cache: CacheTree
        ) -> [(identifier: ElementIdentifier, node: LayoutResultNode)] {
            guard children.isEmpty == false else {
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
                let currentChildCache = cache.subcache(
                    index: index,
                    of: children.count,
                    element: currentChild.element
                )

                let resultNode = LayoutResultNode(
                    element: currentChild.element,
                    layoutAttributes: currentChildLayoutAttributes,
                    environment: environment,
                    children: currentChild.content.performLayout(
                        attributes: currentChildLayoutAttributes,
                        environment: environment,
                        cache: currentChildCache
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
            children.enumerated().map { index, child in
                let childContent = child.content
                let childCache = cache.subcache(
                    index: index,
                    of: children.count,
                    element: child.element
                )
                let measurable = Measurer { constraint -> CGSize in
                    childContent.measure(
                        in: constraint,
                        environment: environment,
                        cache: childCache
                    )
                }

                return (child.traits, measurable)
            }
        }

//        func children(in context: LayoutContext) -> [Element] {
//            return children.map { $0.element }
//        }

        struct Child {

            var traits: LayoutType.Traits
            var key: AnyHashable?
            var content: ElementContent
            var element: Element

        }
    }
}


struct EnvironmentAdaptingStorage: ContentStorage {
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
            environment: environment,
            children: child.content.performLayout(
                attributes: childAttributes,
                environment: environment,
                cache: cache.subcache(element: child)
            )
        )

        return [(identifier, node)]
    }

    func measure(in constraint: SizeConstraint, environment: Environment, cache: CacheTree) -> CGSize {
        cache.get(constraint) { constraint -> CGSize in
            let environment = adapted(environment: environment)
            return child.content.measure(
                in: constraint,
                environment: environment,
                cache: cache.subcache(element: child)
            )
        }
    }

    func adapted(environment: Environment) -> Environment {
        var environment = environment
        adapter(&environment)
        return environment
    }
}

/// Content storage that defers creation of its child until measurement or layout time.
struct LazyStorage: ContentStorage {
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
            environment: environment,
            children: child.content.performLayout(
                attributes: childAttributes,
                environment: environment,
                cache: cache.subcache(element: child)
            )
        )

        return [(identifier, node)]
    }

    func measure(in constraint: SizeConstraint, environment: Environment, cache: CacheTree) -> CGSize {
        cache.get(constraint) { constraint -> CGSize in
            let child = buildChild(in: constraint, environment: environment)
            return child.content.measure(
                in: constraint,
                environment: environment,
                cache: cache.subcache(element: child)
            )
        }
    }

    func buildChild(in constraint: SizeConstraint, environment: Environment) -> Element {
        builder(constraint, environment)
    }
}


struct MeasurableStorage: ContentStorage {

    let childCount = 0

    let measurer: (SizeConstraint, Environment) -> CGSize

    func performLayout(
        attributes: LayoutAttributes,
        environment: Environment,
        cache: CacheTree
    ) -> [(identifier: ElementIdentifier, node: LayoutResultNode)] {
        []
    }

    func measure(in constraint: SizeConstraint, environment: Environment, cache: CacheTree) -> CGSize {
        cache.get(constraint) { constraint in
            measurer(constraint, environment)
        }
    }
}


// All layout is ultimately performed by the `Layout` protocol – this implementations delegates to a wrapped
// `SingleChildLayout` implementation for use in elements with a single child.
fileprivate struct SingleChildLayoutHost: Layout, SPLayout {

    private var wrapped: SingleChildLayout & SPSingleChildLayout

    init(wrapping layout: SingleChildLayout & SPSingleChildLayout) {
        wrapped = layout
    }

    func measure(in constraint: SizeConstraint, items: [(traits: (), content: Measurable)]) -> CGSize {
        precondition(items.count == 1)
        return wrapped.measure(in: constraint, child: items.map { $0.content }.first!)
    }

    func layout(size: CGSize, items: [(traits: (), content: Measurable)]) -> [LayoutAttributes] {
        precondition(items.count == 1)
        return [
            wrapped.layout(size: size, child: items.map { $0.content }.first!),
        ]
    }

    func layout(in context: SPLayoutContext, children: [SPLayoutChild]) -> SPLayoutAttributes {
        wrapped.layout(in: context, child: children[0].layoutable)
    }
}


// Used for elements with a single child that requires no custom layout
fileprivate struct PassthroughLayout: SingleChildLayout, SPSingleChildLayout {

    func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {
        child.measure(in: constraint)
    }

    func layout(size: CGSize, child: Measurable) -> LayoutAttributes {
        LayoutAttributes(size: size)
    }

    func layout(in context: SPLayoutContext, child: SPLayoutable) -> SPLayoutAttributes {
        SPLayoutAttributes(
            size: child.layout(in: context.proposedSize),
            childPositions: [.zero]
        )
    }
}


// Used for empty elements with an intrinsic size
fileprivate struct MeasurableLayout: Layout, SPLayout {

    var measurable: Measurable

    func measure(in constraint: SizeConstraint, items: [(traits: (), content: Measurable)]) -> CGSize {
        precondition(items.isEmpty)
        return measurable.measure(in: constraint)
    }

    func layout(size: CGSize, items: [(traits: (), content: Measurable)]) -> [LayoutAttributes] {
        precondition(items.isEmpty)
        return []
    }

    func layout(in context: SPLayoutContext, children: [SPLayoutChild]) -> SPLayoutAttributes {
        SPLayoutAttributes(
            size: measurable.measure(in: .init(context.proposedSize)),
            childPositions: []
        )
    }
}

struct Measurer: Measurable {
    var _measure: (SizeConstraint) -> CGSize
    func measure(in constraint: SizeConstraint) -> CGSize {
        _measure(constraint)
    }
}
