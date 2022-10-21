import UIKit

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
        // TODO: switch on layoutMode
        storage.measure(in: constraint, environment: environment, cache: cache)
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
        // TODO: Support special layout attributes type that allows unspecified dimensions?
        attributes: LayoutAttributes,
        environment: Environment
    ) -> [IdentifiedNode] {
        storage.performSinglePassLayout(attributes: attributes, environment: environment)
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
    public init(
        child: Element,
        key: AnyHashable? = nil,
        layout: SingleChildLayout
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


fileprivate protocol ContentStorage: SPContentStorage {
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

extension ContentStorage {
    func sizeThatFits(proposal: ProposedViewSize, environment: Environment) -> CGSize {
        fatalError("\(type(of: self)) has not implemented single pass layout")
    }

    func performSinglePassLayout(
        attributes: LayoutAttributes,
        environment: Environment
    ) -> [IdentifiedNode] {
        fatalError("\(type(of: self)) has not implemented single pass layout")
    }
}

// struct SPNodeLayout {
//    var identifier: ElementIdentifier
//    var node: LayoutResultNode
// }

typealias IdentifiedNode = (identifier: ElementIdentifier, node: LayoutResultNode)

protocol SPContentStorage {
    func sizeThatFits(proposal: ProposedViewSize, environment: Environment) -> CGSize

    func performSinglePassLayout(
        attributes: LayoutAttributes,
        environment: Environment
    ) -> [IdentifiedNode]
}


extension ElementContent {

    public struct Builder<LayoutType: Layout>: ContentStorage {

        /// The layout object that is ultimately responsible for measuring
        /// and layout tasks.
        public var layout: LayoutType

        /// Child elements.
        fileprivate var children: [Child] = []

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

        fileprivate struct Child {

            var traits: LayoutType.Traits
            var key: AnyHashable?
            var content: ElementContent
            var element: Element

        }
    }
}

extension ElementContent: Sizable {
    func sizeThatFits(proposal: ProposedViewSize, environment: Environment) -> CGSize {
        storage.sizeThatFits(proposal: proposal, environment: environment)
    }
}

extension ElementContent.Builder {
    func sizeThatFits(proposal: ProposedViewSize, environment: Environment) -> CGSize {
        let subviews = children.map { child in
            LayoutSubview(
                element: child.element,
                content: child.content,
                environment: environment
            )
        }
        return layout.sizeThatFits(proposal: proposal, subviews: subviews)
    }

    func performSinglePassLayout(attributes: LayoutAttributes, environment: Environment) -> [IdentifiedNode] {

        let proposal = ProposedViewSize(attributes.bounds.size)
        let subviews = children.map { child in
            LayoutSubview(
                element: child.element,
                content: child.content,
                environment: environment
            )
        }

        let bounds = CGRect(origin: .zero, size: attributes.bounds.size)
        layout.placeSubviews(
            in: bounds,
            proposal: proposal,
            subviews: subviews
        )

        let childAttributesCollection: [LayoutAttributes] = subviews.map { subview in
            let placement = subview.placement
                ?? .init(position: attributes.center, anchor: .center, size: .proposal(proposal))

            let size: CGSize
            if let width = placement.size.width, let height = placement.size.height {
                size = .init(width: width, height: height)
                print("\(type(of: subview.element)) placed at fixed size \(size)")
            } else {
                let measuredSize = subview.sizeThatFits(placement.size.proposal)
                size = .init(
                    width: placement.size.width ?? measuredSize.width,
                    height: placement.size.height ?? measuredSize.height
                )
                print("\(type(of: subview.element)) placed at measured \(measuredSize) and resolved to \(size)")
            }

            let frame = CGRect(
                origin: placement.origin(for: size),
                size: size
            )
            print("\(type(of: subview.element)) frame \(frame)")

            return LayoutAttributes(frame: frame)
        }

        var identifierFactory = ElementIdentifier.Factory(elementCount: children.count)

        let identifiedNodes: [IdentifiedNode] = children.indexedMap { index, child in
            let childAttributes = childAttributesCollection[index]
            let identifier = identifierFactory.nextIdentifier(
                for: type(of: child.element),
                key: child.key
            )

            let node = LayoutResultNode(
                element: child.element,
                layoutAttributes: childAttributes,
                environment: environment,
                children: child.content.performSinglePassLayout(
                    attributes: childAttributes,
                    environment: environment
                )
            )
            print("\(type(of: child.element)) result \(node.layoutAttributes.frame)")
            return (identifier: identifier, node: node)
        }
        return identifiedNodes
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

    func sizeThatFits(proposal: ProposedViewSize, environment: Environment) -> CGSize {
        let constraint = SizeConstraint(proposal)
        return measurer(constraint, environment)
    }

    func performSinglePassLayout(attributes: LayoutAttributes, environment: Environment) -> [IdentifiedNode] {
        []
    }
}

extension SizeConstraint {
    init(_ proposal: ProposedViewSize) {
        width = .init(singlePassProposal: proposal.width)
        height = .init(singlePassProposal: proposal.height)
    }
}

extension SizeConstraint.Axis {
    init(singlePassProposal: CGFloat?) {
        if let singlePassProposal = singlePassProposal {
            self = .atMost(singlePassProposal)
        } else {
            self = .unconstrained
        }
    }
}


// All layout is ultimately performed by the `Layout` protocol – this implementations delegates to a wrapped
// `SingleChildLayout` implementation for use in elements with a single child.
fileprivate struct SingleChildLayoutHost: Layout {

    private var wrapped: SingleChildLayout

    init(wrapping layout: SingleChildLayout) {
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

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews) -> CGSize {
        precondition(subviews.count == 1)
        return wrapped.sizeThatFits(proposal: proposal, subview: subviews[0])
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews) {
        precondition(subviews.count == 1)
        return wrapped.placeSubview(in: bounds, proposal: proposal, subview: subviews[0])
    }
}


// Used for elements with a single child that requires no custom layout
fileprivate struct PassthroughLayout: SingleChildLayout {

    func measure(in constraint: SizeConstraint, child: Measurable) -> CGSize {
        child.measure(in: constraint)
    }

    func layout(size: CGSize, child: Measurable) -> LayoutAttributes {
        LayoutAttributes(size: size)
    }

    func sizeThatFits(proposal: ProposedViewSize, subview: LayoutSubview) -> CGSize {
        subview.sizeThatFits(proposal)
    }

    func placeSubview(in bounds: CGRect, proposal: ProposedViewSize, subview: LayoutSubview) {
        subview.place(at: .zero, size: proposal.replacingUnspecifiedDimensions())
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
