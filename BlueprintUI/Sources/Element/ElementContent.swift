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

    /// The number of children the `ElementContent` has.
    /// Delegates to `storage` (`ContentStorage`).
    var childCount: Int {
        storage.childCount
    }

    fileprivate init(storage: ContentStorage) {
        self.storage = storage
    }

    /// Measures the content, returning the desired size.
    /// Delegates to `storage` (`ContentStorage`).
    func measure(
        in constraint: SizeConstraint,
        with environment: Environment,
        state: ElementState
    ) -> CGSize {
        autoreleasepool {
            self.storage.measure(in: constraint, with: environment, state: state)
        }
    }

    /// Lays out the content, returning a tree of `LayoutResultNode` values
    /// that can be  used to drive a layout process.
    ///
    /// Delegates to `storage` (`ContentStorage`).
    func performLayout(
        in size: CGSize,
        with environment: Environment,
        state: ElementState
    ) -> [LayoutResultNode] {
        autoreleasepool {
            storage.performLayout(
                in: size,
                with: environment,
                state: state
            )
        }
    }

    /// Using a tree of `LayoutResultNode` values, enumerates
    /// all children to return their `ElementState`, `Element`,
    /// and relevant `LayoutResultNode` values.
    ///
    /// ## Note
    /// This method does _not_ invoke the `forEach` block for the initial reciever.
    /// If you want to perform work on the reciever, do it before calling this method.
    ///
    /// Delegates to `storage` (`ContentStorage`).
    func forEachElement(
        in size: CGSize,
        with environment: Environment,
        children childNodes: [LayoutResultNode],
        state: ElementState,
        forEach: (ForEachElementContext) -> Void
    ) {
        autoreleasepool {
            storage.forEachElement(
                in: size,
                with: environment,
                children: childNodes,
                state: state,
                forEach: forEach
            )
        }
    }

    /// Using a tree of `LayoutResultNode` values, enumerates
    /// all children to return their `ElementState`, `Element`,
    /// and relevant `LayoutResultNode` values.
    ///
    /// ## Note
    /// This method does _not_ invoke the `forEach` block for the initial reciever.
    /// If you want to perform work on the reciever, do it before calling this method.
    ///
    /// Delegates to `storage` (`ContentStorage`).
    fileprivate func forEachElement(
        with node: LayoutResultNode,
        environment: Environment,
        state: ElementState,
        forEach: (ForEachElementContext) -> Void
    ) {
        forEachElement(
            in: node.layoutAttributes.bounds.size,
            with: environment,
            children: node.children,
            state: state,
            forEach: forEach
        )
    }
}

extension ElementContent {

    /// Measures the required size of this element's content.
    ///
    /// - Parameters:
    ///   - constraint: The size constraint.
    ///   - environment: The environment to measure in.
    /// - returns: The layout size needed by this content.
    public func measure(in constraint: SizeConstraint, environment: Environment) -> CGSize {
        autoreleasepool {
            let element = MeasurementElement(content: self)
            let root = ElementStateTree(name: "ElementContent.measure")

            let (_, size) = root.performUpdate(with: element, in: environment) { state in
                self.measure(
                    in: constraint,
                    with: environment,
                    state: state
                )
            }

            return size
        }
    }

    /// A private element we can use as the root of the `ElementStateTree`
    /// when calling `ElementContent.measure`.
    private struct MeasurementElement: Element {

        let content: ElementContent

        func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
            nil
        }
    }
}


extension ElementContent {

    /// Creates a new `ElementContent` which uses the provided element to measure its
    /// size, but does not place the element as a child in the final, laid out hierarchy.
    ///
    /// This is useful if you are placing the element in a nested `BlueprintView`, for example (eg
    /// to create a stateful element) and just need this element to be correctly sized.
    public init(byMeasuring element: Element) {
        storage = MeasureNestedElementStorage(element: element)
    }

    private struct MeasureNestedElementStorage: ContentStorage {

        let element: Element

        let childCount: Int = 0

        func measure(
            in constraint: SizeConstraint,
            with environment: Environment,
            state: ElementState
        ) -> CGSize {

            let childState = state.childState(
                for: element,
                in: environment,
                with: .identifier(for: element, key: nil, count: 1),
                kind: .measurementOnly
            )

            precondition(type(of: element) == type(of: childState.element.latest))

            return childState.measure(in: constraint, with: environment) { environment in
                childState.elementContent.measure(in: constraint, with: environment, state: childState)
            }
        }

        func performLayout(
            in size: CGSize,
            with environment: Environment,
            state: ElementState
        ) -> [LayoutResultNode] {
            []
        }

        func forEachElement(
            in size: CGSize,
            with environment: Environment,
            children childNodes: [LayoutResultNode],
            state: ElementState,
            forEach: (ElementContent.ForEachElementContext) -> Void
        ) {
            precondition(childNodes.isEmpty, "Expected no child nodes for a layout-only element.")

            /// No-op; we have no children so we won't enumerate them.
            ///
            /// Important: This means we also won't update measurement-only children
            /// with their latest instance versions, but that's OK, since we're also not applying
            /// them to real views anyway – that happens in the nested blueprint view.
            ///
            /// Once we're able to share this measurement and layout across blueprint views,
            /// we will be able to finish the bridge here.
        }
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
    public init(
        child: Element
    ) {
        storage = SingleChildStorage(element: child)
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
        self = ElementContent { _ in intrinsicSize }
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
        environment adapter: @escaping (inout Environment) -> Void
    ) {
        storage = EnvironmentAdaptingStorage(
            adapter: adapter,
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


extension ElementContent {

    struct ForEachElementContext {

        var state: ElementState
        var element: Element
        var layoutNode: LayoutResultNode

    }
}


/// The underlying type that backs the `ElementContent`.
fileprivate protocol ContentStorage {

    var childCount: Int { get }

    func measure(
        in constraint: SizeConstraint,
        with environment: Environment,
        state: ElementState
    ) -> CGSize

    func performLayout(
        in size: CGSize,
        with environment: Environment,
        state: ElementState
    ) -> [LayoutResultNode]

    func forEachElement(
        in size: CGSize,
        with environment: Environment,
        children childNodes: [LayoutResultNode],
        state: ElementState,
        forEach: (ElementContent.ForEachElementContext) -> Void
    )
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
            let identifier = identifierFactory.nextIdentifier(for: element, key: key)

            let child = Child(
                traits: traits,
                identifier: identifier,
                element: element
            )

            children.append(child)
        }

        private var identifierFactory = ElementIdentifier.Factory(elementCount: 1)

        // MARK: ContentStorage

        var childCount: Int {
            children.count
        }

        func measure(
            in constraint: SizeConstraint,
            with environment: Environment,
            state: ElementState
        ) -> CGSize {
            state.measure(in: constraint, with: environment) { environment in

                Logger.logMeasureStart(
                    object: state.signpostRef,
                    description: state.name,
                    constraint: constraint
                )

                defer { Logger.logMeasureEnd(object: state.signpostRef) }

                let layoutItems = self.layoutItems(state: state, environment: environment)

                return layout.measure(
                    in: constraint,
                    items: layoutItems
                )
            }
        }

        func performLayout(
            in size: CGSize,
            with environment: Environment,
            state: ElementState
        ) -> [LayoutResultNode] {
            guard children.isEmpty == false else {
                return []
            }

            return state.layout(in: size, with: environment) { environment in

                let layoutItems = self.layoutItems(state: state, environment: environment)

                let childAttributes = layout.layout(
                    size: size,
                    items: layoutItems
                )

                return childAttributes.indexedMap { index, currentChildLayoutAttributes in

                    let currentChild = children[index]
                    let identifier = currentChild.identifier

                    let childState = state.childState(for: currentChild.element, in: environment, with: identifier)

                    return LayoutResultNode(
                        identifier: identifier,
                        layoutAttributes: currentChildLayoutAttributes,
                        environment: environment,
                        element: childState.element,
                        children: childState.elementContent.performLayout(
                            in: currentChildLayoutAttributes.bounds.size,
                            with: environment,
                            state: childState
                        )
                    )
                }
            }
        }

        func forEachElement(
            in size: CGSize,
            with environment: Environment,
            children childNodes: [LayoutResultNode],
            state: ElementState,
            forEach: (ElementContent.ForEachElementContext) -> Void
        ) {
            precondition(childNodes.count == children.count)

            children.indexedForEach { index, child in

                let childState = state.childState(for: child.element, in: environment, with: child.identifier)

                let childNode = childNodes[index]

                forEach(.init(state: childState, element: child.element, layoutNode: childNode))

                childState.elementContent.forEachElement(
                    with: childNode,
                    environment: environment,
                    state: childState,
                    forEach: forEach
                )
            }
        }

        private func layoutItems(
            state: ElementState,
            environment: Environment
        ) -> [(traits: LayoutType.Traits, content: Measurable)] {

            /// **Note**: We are intentionally using our `indexedMap(...)` and not `enumerated().map(...)`
            /// here; because the enumerated version is about 25% slower. Because this
            /// is an extremely hot codepath; this additional performance matters, so we will
            /// keep track of the index ourselves.

            children.indexedMap { index, child in

                let childState = state.childState(for: child.element, in: environment, with: child.identifier)

                let measurable = Measurer { constraint in
                    childState.elementContent.measure(
                        in: constraint,
                        with: environment,
                        state: childState
                    )
                }

                return (traits: child.traits, measurable)
            }
        }

        fileprivate struct Child {

            var traits: LayoutType.Traits
            var identifier: ElementIdentifier
            var element: Element

        }
    }
}


/// Storage used to store "layout neutral" elements, where they will only have one child,
/// and the measurement of the element is the same as the child.
private struct SingleChildStorage: ContentStorage {

    let childCount: Int = 1

    var element: Element

    func measure(
        in constraint: SizeConstraint,
        with environment: Environment,
        state: ElementState
    ) -> CGSize {

        let identifier = ElementIdentifier.identifierFor(singleChild: element)

        let child = state.childState(for: element, in: environment, with: identifier)

        return child.elementContent.measure(in: constraint, with: environment, state: child)
    }

    func performLayout(
        in size: CGSize,
        with environment: Environment,
        state: ElementState
    ) -> [LayoutResultNode] {
        state.layout(in: size, with: environment) { environment in
            let childAttributes = LayoutAttributes(size: size)

            let identifier = ElementIdentifier.identifierFor(singleChild: element)

            let childState = state.childState(for: element, in: environment, with: identifier)

            let node = LayoutResultNode(
                identifier: identifier,
                layoutAttributes: childAttributes,
                environment: environment,
                element: childState.element,
                children: childState.elementContent.performLayout(
                    in: size,
                    with: environment,
                    state: childState
                )
            )

            return [node]
        }
    }

    func forEachElement(
        in size: CGSize,
        with environment: Environment,
        children childNodes: [LayoutResultNode],
        state: ElementState,
        forEach: (ElementContent.ForEachElementContext) -> Void
    ) {
        precondition(childNodes.count == 1)

        let childState = state.childState(for: element, in: environment, with: .identifierFor(singleChild: element))

        let childNode = childNodes[0]

        forEach(.init(state: childState, element: element, layoutNode: childNode))

        childState.elementContent.forEachElement(
            with: childNode,
            environment: environment,
            state: childState,
            forEach: forEach
        )
    }
}


/// A type used to delay element creation until the `Environment` is available,
/// used by the `AdaptedEnvironment` element.
private struct EnvironmentAdaptingStorage: ContentStorage {

    let childCount = 1

    /// During measurement or layout, the environment adapter will be applied
    /// to the environment before passing it to the wrapped child element.
    var adapter: (inout Environment) -> Void

    var child: Element

    func forEachElement(
        in size: CGSize,
        with environment: Environment,
        children childNodes: [LayoutResultNode],
        state: ElementState,
        forEach: (ElementContent.ForEachElementContext) -> Void
    ) {
        precondition(childNodes.count == 1)

        var environment = environment
        adapter(&environment)

        let childState = state.childState(for: child, in: environment, with: .identifierFor(singleChild: child))

        let childNode = childNodes[0]

        forEach(.init(state: childState, element: child, layoutNode: childNode))

        childState.elementContent.forEachElement(
            with: childNode,
            environment: environment,
            state: childState,
            forEach: forEach
        )
    }

    func performLayout(
        in size: CGSize,
        with environment: Environment,
        state: ElementState
    ) -> [LayoutResultNode] {

        state.layout(in: size, with: environment) { environment in
            let environment = adapted(environment: environment)

            let childAttributes = LayoutAttributes(size: size)

            let identifier = ElementIdentifier.identifierFor(singleChild: child)

            let childState = state.childState(for: child, in: environment, with: identifier)

            let node = LayoutResultNode(
                identifier: identifier,
                layoutAttributes: childAttributes,
                environment: environment,
                element: childState.element,
                children: childState.elementContent.performLayout(
                    in: size,
                    with: environment,
                    state: childState
                )
            )

            return [node]
        }
    }

    func measure(
        in constraint: SizeConstraint,
        with environment: Environment,
        state: ElementState
    ) -> CGSize {
        state.measure(in: constraint, with: environment) { environment in

            let environment = self.adapted(environment: environment)
            let identifier = ElementIdentifier.identifierFor(singleChild: child)
            let childState = state.childState(for: child, in: environment, with: identifier)

            return childState.elementContent.measure(
                in: constraint,
                with: environment,
                state: childState
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
/// This is used for types dependent on sizing, such as `GeometryReader`.
private struct LazyStorage: ContentStorage {

    let childCount = 1

    var builder: (ElementContent.LayoutPhase, SizeConstraint, Environment) -> Element

    func measure(
        in constraint: SizeConstraint,
        with environment: Environment,
        state: ElementState
    ) -> CGSize {
        state.measure(in: constraint, with: environment) { environment in

            let child = buildChild(for: .measurement, in: constraint, environment: environment)
            let identifier = ElementIdentifier.identifierFor(singleChild: child)
            let childState = state.childState(for: child, in: environment, with: identifier)

            return childState.elementContent.measure(
                in: constraint,
                with: environment,
                state: childState
            )
        }
    }

    func performLayout(
        in size: CGSize,
        with environment: Environment,
        state: ElementState
    ) -> [LayoutResultNode] {
        state.layout(in: size, with: environment) { environment in
            let constraint = SizeConstraint(size)
            let child = buildChild(for: .layout, in: constraint, environment: environment)

            let childAttributes = LayoutAttributes(size: size)

            let identifier = ElementIdentifier.identifierFor(singleChild: child)

            let childState = state.childState(for: child, in: environment, with: identifier)

            let node = LayoutResultNode(
                identifier: identifier,
                layoutAttributes: childAttributes,
                environment: environment,
                element: childState.element,
                children: childState.elementContent.performLayout(
                    in: size,
                    with: environment,
                    state: childState
                )
            )

            return [node]
        }
    }

    func forEachElement(
        in size: CGSize,
        with environment: Environment,
        children childNodes: [LayoutResultNode],
        state: ElementState,
        forEach: (ElementContent.ForEachElementContext) -> Void
    ) {
        precondition(childNodes.count == 1)

        let element = builder(.layout, SizeConstraint(size), environment)

        let childState = state.childState(for: element, in: environment, with: .identifierFor(singleChild: element))

        let childNode = childNodes[0]

        forEach(.init(state: childState, element: element, layoutNode: childNode))

        childState.elementContent.forEachElement(
            with: childNode,
            environment: environment,
            state: childState,
            forEach: forEach
        )
    }

    private func buildChild(
        for phase: ElementContent.LayoutPhase,
        in constraint: SizeConstraint,
        environment: Environment
    ) -> Element {
        builder(phase, constraint, environment)
    }
}

/// Storage used to perform a measurement, but for an element
/// that otherwise has no children.
private struct MeasurableStorage: ContentStorage {

    let childCount = 0

    let measurer: (SizeConstraint, Environment) -> CGSize

    func performLayout(
        in size: CGSize,
        with environment: Environment,
        state: ElementState
    ) -> [LayoutResultNode] {
        []
    }

    func measure(in constraint: SizeConstraint, with environment: Environment, state: ElementState) -> CGSize {

        state.measure(in: constraint, with: environment) { environment in
            measurer(constraint, environment)
        }
    }

    func forEachElement(
        in size: CGSize,
        with environment: Environment,
        children childNodes: [LayoutResultNode],
        state: ElementState,
        forEach: (ElementContent.ForEachElementContext) -> Void
    ) {
        // No-op; we have no children.
    }
}


// All layout is ultimately performed by the `Layout` protocol – this implementations delegates to a wrapped
// `SingleChildLayout` implementation for use in elements with a single child.
fileprivate struct SingleChildLayoutHost: Layout {

    private var wrapped: SingleChildLayout

    init(wrapping layout: SingleChildLayout) {
        wrapped = layout
    }

    // MARK: Layout

    func measure(in constraint: SizeConstraint, items: [(traits: (), content: Measurable)]) -> CGSize {
        precondition(items.count == 1)

        return wrapped.measure(
            in: constraint,
            child: items[0].content
        )
    }

    func layout(size: CGSize, items: [(traits: (), content: Measurable)]) -> [LayoutAttributes] {
        precondition(items.count == 1)

        return [
            wrapped.layout(
                size: size,
                child: items[0].content
            ),
        ]
    }
}


// Used for empty elements with an intrinsic size
fileprivate struct MeasurableLayout: Layout {

    let measurable: Measurable

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

    let provider: (SizeConstraint) -> CGSize

    func measure(
        in constraint: SizeConstraint
    ) -> CGSize {
        autoreleasepool {
            self.provider(constraint)
        }
    }
}

