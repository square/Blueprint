import UIKit

/// Represents the content of an element.
public struct ElementContent {

    let storage: ContentStorage

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

        storage = builder
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
            cache: CacheFactory.makeCache(name: "ElementContent"),
            layoutMode: RenderContext.current?.layoutMode ?? environment.layoutMode
        )
    }

    func measure(
        in constraint: SizeConstraint,
        environment: Environment,
        cache: CacheTree,
        layoutMode: LayoutMode
    ) -> CGSize {
        switch layoutMode {
        case .standard:
            return storage.measure(in: constraint, environment: environment, cache: cache)
        case .singlePass:
            return storage.sizeThatFits(
                proposal: constraint,
                context: .init(
                    // TODO: Hoist upward?
                    cache: SPCacheNode(
                        path: "m",
                        options: SPCacheOptions(
                            hintRangeBoundaries: true,
                            searchUnconstrainedKeys: false
                        )
                    ),
                    environment: environment
                )
            )
        case .strictSinglePass:
            let context = StrictLayoutContext(
                path: .empty,
                cache: .init(),
                proposedSize: constraint,
                mode: AxisVarying(horizontal: .natural, vertical: .natural)
            )
            let subtree = performStrictLayout(
                in: context,
                environment: environment
            )
            return subtree
                .intermediate
                .size
        }
    }

    fileprivate func measure(in constraint: SizeConstraint, environment: Environment, cache: CacheTree) -> CGSize {
        storage.measure(in: constraint, environment: environment, cache: cache)
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

    func performSinglePassLayout(
        proposal: SizeConstraint,
        context: SPLayoutContext
    ) -> [IdentifiedNode] {
        storage.performSinglePassLayout(
            proposal: proposal,
            context: context
        )
    }

    func performStrictLayout(
        in context: StrictLayoutContext,
        environment: Environment
    ) -> StrictSubtreeResult {
        storage.strictLayout(in: context, environment: environment)
    }

}

public struct SPLayoutContext {
    var attributes: LayoutAttributes
    var environment: Environment
    var cache: SPCacheNode
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
        storage = LazyStorage { _, size, env in
            builder(size, env)
        }
    }

    init(
        build builder: @escaping (LayoutPhase, SizeConstraint, Environment) -> Element
    ) {
        storage = LazyStorage(builder: builder)
    }

    enum LayoutPhase {
        case measurement
        case layout
    }
}

extension ElementContent {

    /// Initializes a new `ElementContent` with the given element and layout.
    ///
    /// - parameter element: The single child element.
    /// - parameter key: The key to use to unique the element during updates.
    /// - parameter layout: The layout that will be used.
    public init<LayoutType: SingleChildLayout>(
        child: Element,
        key: AnyHashable? = nil,
        layout: LayoutType
    ) {
        self = ElementContent(layout: SingleChildLayoutHost(wrapping: layout)) {
            $0.add(key: key, element: child)
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
    ///
    /// - parameter measurable: How to measure the `ElementContent`.
    public init(measurable: Measurable) {
        storage = MeasurableStorage(measurer: { constraint, environment in
            measurable.measure(in: constraint)
        })
    }

    /// Initializes a new `ElementContent` with no children that delegates to the provided measure function.
    ///
    /// - parameter measureFunction: How to measure the `ElementContent` in the given `SizeConstraint`.
    public init(
        measureFunction: @escaping (SizeConstraint) -> CGSize
    ) {
        self = ElementContent { constraint, _ in
            measureFunction(constraint)
        }
    }

    /// Initializes a new `ElementContent` with no children that delegates to the provided measure function.
    ///
    /// - parameter measureFunction: How to measure the `ElementContent` in the given `SizeConstraint` and `Environment`.
    public init(
        measureFunction: @escaping (SizeConstraint, Environment) -> CGSize
    ) {
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
    /// - parameter environmentAdapter: How to adapt the `Environment` for the child and elements further down the tree.
    public init(
        child: Element,
        environment environmentAdapter: @escaping (inout Environment) -> Void
    ) {
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


protocol ContentStorage: SPContentStorage, StrictContentStorage {
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

    public struct Builder<LayoutType: Layout & StrictLayout>: ContentStorage {

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

            /// **Note**: We are intentionally using our `indexedMap(...)` and not `enumerated().map(...)`
            /// here; because the enumerated version is about 25% slower. Because this
            /// is an extremely hot codepath; this additional performance matters, so we will
            /// keep track of the index ourselves.

            children.indexedMap { index, child in
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

        struct Child {

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

    private func adapted(environment: Environment) -> Environment {
        var environment = environment
        adapter(&environment)
        return environment
    }
}

extension EnvironmentAdaptingStorage {

    func sizeThatFits(proposal: SizeConstraint, context: MeasureContext) -> CGSize {
        context.cache.get(key: proposal) { proposal in
            let environment = adapted(environment: context.environment)
            let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)
            let context = MeasureContext(
                cache: context.cache.subcache(key: identifier),
                environment: environment
            )
            return child.content.sizeThatFits(proposal: proposal, context: context)
        }
    }

    func performSinglePassLayout(proposal: SizeConstraint, context: SPLayoutContext) -> [IdentifiedNode] {
        let environment = adapted(environment: context.environment)

        let childAttributes = LayoutAttributes(size: context.attributes.bounds.size)

        let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)

        let context = SPLayoutContext(
            attributes: context.attributes,
            environment: environment,
            cache: context.cache.subcache(key: identifier)
        )

        let node = LayoutResultNode(
            element: child,
            layoutAttributes: childAttributes,
            environment: environment,
            children: child.content.performSinglePassLayout(
                proposal: proposal,
                context: context
            )
        )

        return [(identifier, node)]
    }
}

/// Content storage that defers creation of its child until measurement or layout time.
private struct LazyStorage: ContentStorage {
    let childCount = 1

    var builder: (ElementContent.LayoutPhase, SizeConstraint, Environment) -> Element

    func performLayout(
        attributes: LayoutAttributes,
        environment: Environment,
        cache: CacheTree
    ) -> [(identifier: ElementIdentifier, node: LayoutResultNode)] {
        let constraint = SizeConstraint(attributes.bounds.size)
        let child = buildChild(for: .layout, in: constraint, environment: environment)
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
            let child = buildChild(for: .measurement, in: constraint, environment: environment)
            return child.content.measure(
                in: constraint,
                environment: environment,
                cache: cache.subcache(element: child)
            )
        }
    }

    private func buildChild(
        for phase: ElementContent.LayoutPhase,
        in constraint: SizeConstraint,
        environment: Environment
    ) -> Element {
        builder(phase, constraint, environment)
    }
}

extension LazyStorage {

    func sizeThatFits(proposal: SizeConstraint, context: MeasureContext) -> CGSize {
        context.cache.get(key: proposal) { proposal in
            let child = buildChild(
                for: .measurement,
                in: proposal,
                environment: context.environment
            )
            let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)
            let context = MeasureContext(
                cache: context.cache.subcache(key: identifier),
                environment: context.environment
            )
            return child.content.sizeThatFits(proposal: proposal, context: context)
        }
    }

    func performSinglePassLayout(proposal: SizeConstraint, context: SPLayoutContext) -> [IdentifiedNode] {
        let child = buildChild(
            for: .layout,
            in: proposal,
            environment: context.environment
        )

        let childAttributes = LayoutAttributes(size: context.attributes.bounds.size)

        let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)

        let context = SPLayoutContext(
            attributes: context.attributes,
            environment: context.environment,
            cache: context.cache.subcache(key: identifier)
        )

        let node = LayoutResultNode(
            element: child,
            layoutAttributes: childAttributes,
            environment: context.environment,
            children: child.content.performSinglePassLayout(
                proposal: proposal,
                context: context
            )
        )

        return [(identifier, node)]
    }
}


private struct MeasurableStorage: ContentStorage {

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

    func sizeThatFits(proposal: SizeConstraint, context: MeasureContext) -> CGSize {
//        context.cache.get(key: proposal) { proposal in
        measurer(proposal, context.environment)
//        }
    }

    func performSinglePassLayout(proposal: SizeConstraint, context: SPLayoutContext) -> [IdentifiedNode] {
        []
    }
}

// MARK: - Strict SPL extensions

extension ElementContent.Builder {

    enum NodesEntry: StrictCacheTreeEntry {
        typealias Value = [StrictLayoutNode]
    }

    func strictLayout(
        in context: StrictLayoutContext,
        environment: Environment
    ) -> StrictSubtreeResult {

        func makeNodes() -> [StrictLayoutNode] {
            var identifierFactory = ElementIdentifier.Factory(elementCount: childCount)
            var nodes: [StrictLayoutNode] = []
            nodes.reserveCapacity(children.count)


            for index in 0..<children.count {
                let child = children[index]
                let childElement = child.element
                let id = identifierFactory.nextIdentifier(for: type(of: childElement), key: child.key)

                let node = StrictLayoutNode(
                    path: context.path,
                    id: id,
                    element: childElement,
                    content: childElement.content,
                    environment: environment,
                    cache: context.cache.subcache(key: index)
                )

                nodes.append(node)
            }

            return nodes
        }
        
        let layoutNodes = context.cache.get(entryType: NodesEntry.self, or: makeNodes)
        
        func makeProposalCaptureNodes() -> [StrictProposalCaptureNode] {
            var nodes: [StrictProposalCaptureNode] = []
            nodes.reserveCapacity(children.count)

            for index in 0..<children.count {
                let layoutNode = layoutNodes[index]
                let node = StrictProposalCaptureNode(
                    mode: context.mode,
                    layoutNode: layoutNode
                )
                nodes.append(node)
            }
            
            return nodes
        }
        
        let nodes = makeProposalCaptureNodes()
        
        var layoutChildren: [(traits: LayoutType.Traits, layoutable: StrictLayoutable)] = []
        layoutChildren.reserveCapacity(children.count)

        for index in (0..<childCount) {
            let node = nodes[index]

            let traits = children[index].traits
            let layoutable = node
            layoutChildren.append((traits, layoutable))
        }

        let intermediateResult = layout.layout(
            in: context,
            children: layoutChildren
        )

        return StrictSubtreeResult(
            intermediate: intermediateResult,
            children: nodes
        )
    }
}


extension EnvironmentAdaptingStorage {
    func strictLayout(
        in context: StrictLayoutContext,
        environment: Environment
    ) -> StrictSubtreeResult {
        let environment = adapted(environment: environment)
        let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)
        let cache = context.cache.subcache(key: 0)

        let layoutNode = StrictLayoutNode(
            path: context.path,
            id: identifier,
            element: child,
            content: child.content,
            environment: environment,
            cache: cache
        )
        let node = StrictProposalCaptureNode(mode: context.mode, layoutNode: layoutNode)

        return StrictSubtreeResult(
            intermediate: NeutralLayout().layout(in: context, child: node),
            children: [node]
        )
    }
}

extension LazyStorage {
    func strictLayout(
        in context: StrictLayoutContext,
        environment: Environment
    ) -> StrictSubtreeResult {
        let child = buildChild(
            for: .layout,
            in: context.proposedSize,
            environment: environment
        )
        let identifier = ElementIdentifier(elementType: type(of: child), key: nil, count: 1)
        let cache = context.cache.subcache(key: 0)

        let layoutNode = StrictLayoutNode(
            path: context.path,
            id: identifier,
            element: child,
            content: child.content,
            environment: environment,
            cache: cache
        )
        let node = StrictProposalCaptureNode(mode: context.mode, layoutNode: layoutNode)

        return StrictSubtreeResult(
            intermediate: NeutralLayout().layout(in: context, child: node),
            children: [node]
        )
    }
}

extension MeasurableStorage {
    func strictLayout(
        in context: StrictLayoutContext,
        environment: Environment
    ) -> StrictSubtreeResult {
        let size = measurer(context.proposedSize, environment)
        return StrictSubtreeResult(
            intermediate: StrictLayoutAttributes(
                size: size,
                childPositions: []
            ),
            children: []
        )
    }
}

// All layout is ultimately performed by the `Layout` protocol – this implementations delegates to a wrapped
// `SingleChildLayout` implementation for use in elements with a single child.
fileprivate struct SingleChildLayoutHost<LayoutType: SingleChildLayout>: Layout, StrictLayout {

    typealias Cache = LayoutType.Cache

    private var wrapped: LayoutType

    init(wrapping layout: LayoutType) {
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

    func sizeThatFits(proposal: SizeConstraint, subviews: Subviews, cache: inout Cache) -> CGSize {
        precondition(subviews.count == 1)

        return wrapped.sizeThatFits(proposal: proposal, subview: subviews[0], cache: &cache)
    }

    func placeSubviews(in bounds: CGRect, proposal: SizeConstraint, subviews: Subviews, cache: inout Cache) {
        precondition(subviews.count == 1)
        return wrapped.placeSubview(in: bounds, proposal: proposal, subview: subviews[0], cache: &cache)
    }

    func makeCache(subviews: Subviews) -> LayoutType.Cache {
        wrapped.makeCache(subview: subviews[0])
    }

    func layout(in context: StrictLayoutContext, children: [StrictLayoutChild]) -> StrictLayoutAttributes {
        precondition(children.count == 1)
        return wrapped.layout(in: context, child: children[0].layoutable)
    }

}

struct Measurer: Measurable {
    var _measure: (SizeConstraint) -> CGSize
    func measure(in constraint: SizeConstraint) -> CGSize {
        _measure(constraint)
    }
}

extension Array {

    /// A `map` implementation that also passes the `index` of each element in the original array.
    ///
    /// This method is more performant than calling `array.enumerated().map(...)` by up
    /// to 25% for large collections, so prefer it when needing an indexed `map` in areas where performance is critical.
    @inlinable func indexedMap<Mapped>(_ map: (Int, Element) -> Mapped) -> [Mapped] {

        let count = self.count

        var mapped = [Mapped]()
        mapped.reserveCapacity(count)

        for index in indices {
            mapped.append(map(index, self[index]))
        }

        return mapped
    }
}
