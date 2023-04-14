import UIKit

/// Represents the content of an element.
public struct ElementContent {

    private let storage: ContentStorage

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
            cacheName: "ElementContent",
            layoutMode: RenderContext.current?.layoutMode ?? environment.layoutMode
        )
    }

    func measure(
        in constraint: SizeConstraint,
        environment: Environment,
        cacheName: String,
        layoutMode: LayoutMode
    ) -> CGSize {
        switch layoutMode {
        case .legacy:
            return measure(
                in: constraint,
                environment: environment,
                cache: CacheFactory.makeCache(name: cacheName)
            )
        case .caffeinated(let options):
            let node = LayoutTreeNode(
                path: cacheName,
                signpostRef: SignpostToken(),
                options: options
            )
            return sizeThatFits(
                proposal: constraint,
                environment: environment,
                node: node
            )
        }
    }

    func measure(in constraint: SizeConstraint, environment: Environment, cache: CacheTree) -> CGSize {
        storage.measure(in: constraint, environment: environment, cache: cache)
    }

    func sizeThatFits(
        proposal: SizeConstraint,
        environment: Environment,
        node: LayoutTreeNode
    ) -> CGSize {
        storage.sizeThatFits(proposal: proposal, environment: environment, node: node)
    }

    public var childCount: Int {
        storage.childCount
    }

    typealias IdentifiedNode = (identifier: ElementIdentifier, node: LayoutResultNode)

    func performLegacyLayout(
        attributes: LayoutAttributes,
        environment: Environment,
        cache: CacheTree
    ) -> [IdentifiedNode] {
        storage.performLegacyLayout(
            attributes: attributes,
            environment: environment,
            cache: cache
        )
    }

    func performCaffeinatedLayout(
        frame: CGRect,
        environment: Environment,
        node: LayoutTreeNode
    ) -> [IdentifiedNode] {
        storage.performCaffeinatedLayout(
            frame: frame,
            environment: environment,
            node: node
        )
    }
}

// MARK: - Layout storage

extension ElementContent {

    /// Used to construct elements that have layout and children.
    public struct Builder<LayoutType: Layout> {

        typealias Child = LayoutStorage<LayoutType>.Child

        /// The layout object that is ultimately responsible for measuring
        /// and layout tasks.
        public var layout: LayoutType

        /// Child elements.
        var children: [Child] = []

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
    }

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

        storage = LayoutStorage(layout: layout, children: builder.children)
    }

    /// Initializes a new `ElementContent` with the given element and layout.
    ///
    /// - parameter element: The single child element.
    /// - parameter key: The key to use to unique the element during updates.
    /// - parameter layout: The layout that will be used.
    public init(
        child: Element,
        key: AnyHashable? = nil,
        layout: some SingleChildLayout
    ) {
        self = ElementContent(layout: SingleChildLayoutHost(wrapping: layout)) {
            $0.add(key: key, element: child)
        }
    }
}

// MARK: - Passthrough storage

extension ElementContent {

    /// Initializes a new `ElementContent` with the given element.
    ///
    /// The given element will be used for measuring, and it will always fill the extent of the parent element.
    ///
    /// - parameter element: The single child element.
    public init(child: Element) {
        storage = PassthroughStorage(child: child)
    }
}

// MARK: - Lazy storage

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

// MARK: - Leaf content

extension ElementContent {

    /// Initializes a new `ElementContent` with no children that delegates to the provided `Measurable`.
    ///
    /// - parameter measurable: How to measure the `ElementContent`.
    public init(measurable: Measurable) {
        self = ElementContent(measureFunction: measurable.measure(in:))
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

// MARK: - Environment adapters

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

// MARK: - Nested element measuring

extension ElementContent {
    /// Creates a new `ElementContent` which uses the provided element to measure its
    /// size, but does not place the element as a child in the final, laid out hierarchy.
    ///
    /// This is useful if you are placing the element in a nested `BlueprintView`, for example (eg
    /// to create a stateful element) and just need this element to be correctly sized.
    public init(measuring element: Element) {
        storage = MeasureElementStorage(child: element)
    }
}

// All layout is ultimately performed by the `Layout` protocol – this implementations delegates to a wrapped
// `SingleChildLayout` implementation for use in elements with a single child.
fileprivate struct SingleChildLayoutHost<WrappedLayout: SingleChildLayout>: Layout {

    typealias Cache = WrappedLayout.Cache

    private var wrapped: WrappedLayout

    init(wrapping layout: WrappedLayout) {
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

    func sizeThatFits(
        proposal: SizeConstraint,
        subelements: Subelements,
        environment: Environment,
        cache: inout Cache
    ) -> CGSize {
        precondition(subelements.count == 1)
        return wrapped.sizeThatFits(
            proposal: proposal,
            subelement: subelements[0],
            environment: environment,
            cache: &cache
        )
    }

    func placeSubelements(
        in size: CGSize,
        subelements: Subelements,
        environment: Environment,
        cache: inout Cache
    ) {
        precondition(subelements.count == 1)
        wrapped.placeSubelement(
            in: size,
            subelement: subelements[0],
            environment: environment,
            cache: &cache
        )
    }

    func makeCache(subelements: Subelements, environment: Environment) -> Cache {
        precondition(subelements.count == 1)
        return wrapped.makeCache(subelement: subelements[0], environment: environment)
    }
}

extension Array {

    /// A `map` implementation that also passes the `index` of each element in the original array.
    ///
    /// This method is more performant than calling `array.enumerated().map(...)` by up
    /// to 25% for large collections, so prefer it when needing an indexed `map` in areas where performance is critical.
    @inlinable func indexedMap<Mapped>(_ map: (Int, Element) -> Mapped) -> [Mapped] {

        let count = count

        var mapped = [Mapped]()
        mapped.reserveCapacity(count)

        for index in indices {
            mapped.append(map(index, self[index]))
        }

        return mapped
    }
}
