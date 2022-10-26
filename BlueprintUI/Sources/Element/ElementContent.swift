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

    fileprivate init(storage: ContentStorage) {
        self.storage = storage
    }

    func measure(
        in constraint: SizeConstraint,
        with environment: Environment,
        states: ElementState
    ) -> CGSize {
        autoreleasepool {
            self.storage.measure(in: constraint, with: environment, states: states)
        }
    }

    public var childCount: Int {
        storage.childCount
    }

    func performLayout(
        in size: CGSize,
        with environment: Environment,
        states: ElementState
    ) -> [LayoutResultNode] // TODO: Turn this into a reference type too
    {
        autoreleasepool {
            storage.performLayout(
                in: size,
                with: environment,
                states: states
            )
        }
    }
}

extension ElementContent {

    // MARK: Measurement & Children
    /// Measures the required size of this element's content.
    /// - Parameters:
    ///   - constraint: The size constraint.
    ///   - environment: The environment to measure in.
    /// - returns: The layout size needed by this content.
    public func measure(in constraint: SizeConstraint, environment: Environment) -> CGSize {
        MeasurementElement(content: self).detachedMeasure(in: constraint, with: environment)
    }

    private struct MeasurementElement: Element {

        var content: ElementContent

        func backingViewDescription(with context: ViewDescriptionContext) -> ViewDescription? {
            nil
        }

    }
}


extension Element {

    // MARK: Measurement & Children

    /// Measures the size needed to display the element within the provided size constraint.
    ///
    /// ### Usage
    /// You usually call this method from within the `measure` method of a `Layout`, or within the
    /// measurement function you provide to an `ElementContent` instance. In either of these cases,
    /// you should pass through the `LayoutContext` provided to you to ensure the measured elements
    /// downstream have full access to their measurement caches, environment, etc.
    /// ```
    /// public var content: ElementContent {
    ///     ElementContent { constraint, context -> CGSize in
    ///         self.wrapped.detachedMeasure(in: constraint, with: context)
    ///     }
    /// }
    /// ```
    public func detachedMeasure(in constraint: SizeConstraint, with environment: Environment) -> CGSize {
        autoreleasepool {
            let root = RootElementState(name: "\(type(of: self)).detachedMeasure", kind: .measurement)
            root.update(with: self, in: environment)

            return self.content.measure(
                in: constraint,
                with: environment,
                states: root.root!
            )
        }
    }
}

extension ElementContent {

    /// Creates a new `ElementContent` which uses the provided element to measure its
    /// size, but does not place the element as a child in the final, laid out hierarchy.
    ///
    /// This is useful if you are placing the element in a nested `BlueprintView`, for example (eg
    /// to create a stateful element) and just need this element to be correctly sized.
    public static func byMeasuring(element: Element) -> Self {
        .init(storage: Storage(element: element))
    }

    // TODO: A way to pass this state down to the actual view

    struct Storage: ContentStorage {

        let element: Element

        let childCount: Int = 0

        func measure(
            in constraint: SizeConstraint,
            with environment: Environment,
            states: ElementState
        ) -> CGSize {

            let childState = states.childState(
                for: element,
                in: environment,
                with: .identifier(for: element, key: nil, count: 1)
            )

            precondition(type(of: element) == type(of: childState.element))

            return childState.measure(in: constraint, with: environment) { environment in
                childState.elementContent.measure(in: constraint, with: environment, states: childState)
            }
        }

        func performLayout(
            in size: CGSize,
            with environment: Environment,
            states: ElementState
        ) -> [LayoutResultNode] {
            []
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


fileprivate protocol ContentStorage {

    var childCount: Int { get }

    func measure(
        in constraint: SizeConstraint,
        with environment: Environment,
        states: ElementState
    ) -> CGSize

    func performLayout(
        in size: CGSize,
        with environment: Environment,
        states: ElementState
    ) -> [LayoutResultNode]
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

        // MARK: ContentStorage

        var childCount: Int {
            children.count
        }

        func measure(
            in constraint: SizeConstraint,
            with environment: Environment,
            states: ElementState
        ) -> CGSize {
            states.measure(in: constraint, with: environment) { environment in

                Logger.logMeasureStart(
                    object: states.signpostRef,
                    description: states.name,
                    constraint: constraint
                )

                defer { Logger.logMeasureEnd(object: states.signpostRef) }

                let layoutItems = self.layoutItems(states: states, environment: environment)

                return layout.measure(
                    in: constraint,
                    items: layoutItems
                )
            }
        }

        func performLayout(
            in size: CGSize,
            with environment: Environment,
            states: ElementState
        ) -> [LayoutResultNode] {
            guard children.isEmpty == false else {
                return []
            }

            let layoutItems = self.layoutItems(states: states, environment: environment)

            let childAttributes = layout.layout(
                size: size,
                items: layoutItems
            )

            var result: [LayoutResultNode] = []
            result.reserveCapacity(children.count)

            for index in 0..<children.count {
                let currentChildLayoutAttributes = childAttributes[index]
                let currentChild = children[index]
                let identifier = layoutItems.all[index].identifier

                let childState = states.childState(for: currentChild.element, in: environment, with: identifier)

                let resultNode = LayoutResultNode(
                    element: currentChild.element,
                    identifier: identifier,
                    layoutAttributes: currentChildLayoutAttributes,
                    environment: environment,
                    state: childState,
                    children: childState.elementContent.performLayout(
                        in: currentChildLayoutAttributes.frame.size,
                        with: environment,
                        states: childState
                    )
                )

                result.append(resultNode)
            }

            return result
        }

        private var identifierFactory = ElementIdentifier.Factory(elementCount: 1)

        private func layoutItems(
            states: ElementState,
            environment: Environment
        ) -> LayoutItems<LayoutType.Traits> {
            /// **Note**: We are intentionally using our `indexedMap(...)` and not `enumerated().map(...)`
            /// here; because the enumerated version is about 25% slower. Because this
            /// is an extremely hot codepath; this additional performance matters, so we will
            /// keep track of the index ourselves.

            LayoutItems(with: children.indexedMap { index, child in

                let childState = states.childState(for: child.element, in: environment, with: child.identifier)

                let measurable = Measurer { constraint in
                    childState.elementContent.measure(
                        in: constraint,
                        with: environment,
                        states: childState
                    )
                }

                return LayoutItems.Item(
                    traits: child.traits,
                    content: measurable,
                    identifier: child.identifier
                )
            })
        }

        fileprivate struct Child {

            var traits: LayoutType.Traits
            var identifier: ElementIdentifier
            var element: Element

        }
    }
}


private struct SingleChildStorage: ContentStorage {

    let childCount: Int = 1

    var element: Element

    func measure(in constraint: SizeConstraint, with environment: Environment, states: ElementState) -> CGSize {

        let identifier = ElementIdentifier.identifier(for: element, key: nil, count: 1)

        let child = states.childState(for: element, in: environment, with: identifier)

        return child.elementContent.measure(in: constraint, with: environment, states: child)
    }

    func performLayout(in size: CGSize, with environment: Environment, states: ElementState) -> [LayoutResultNode] {

        let childAttributes = LayoutAttributes(size: size)

        let identifier = ElementIdentifier.identifier(for: element, key: nil, count: 1)

        let childState = states.childState(for: element, in: environment, with: identifier)

        let node = LayoutResultNode(
            element: element,
            identifier: identifier,
            layoutAttributes: childAttributes,
            environment: environment,
            state: childState,
            children: childState.elementContent.performLayout(
                in: size,
                with: environment,
                states: childState
            )
        )

        return [node]
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
        in size: CGSize,
        with environment: Environment,
        states: ElementState
    ) -> [LayoutResultNode] {
        let environment = adapted(environment: environment)

        let childAttributes = LayoutAttributes(size: size)

        let identifier = ElementIdentifier.identifier(for: child, key: nil, count: 1)

        let childState = states.childState(for: child, in: environment, with: identifier)

        let node = LayoutResultNode(
            element: child,
            identifier: identifier,
            layoutAttributes: childAttributes,
            environment: environment,
            state: childState,
            children: childState.elementContent.performLayout(
                in: size,
                with: environment,
                states: childState
            )
        )

        return [node]
    }

    func measure(
        in constraint: SizeConstraint,
        with environment: Environment,
        states: ElementState
    ) -> CGSize {
        states.measure(in: constraint, with: environment) { environment in

            let environment = self.adapted(environment: environment)
            let identifier = ElementIdentifier.identifier(for: child, key: nil, count: 1)
            let childState = states.childState(for: child, in: environment, with: identifier)

            return childState.elementContent.measure(
                in: constraint,
                with: environment,
                states: childState
            )
        }
    }

    private func adapted(environment: Environment) -> Environment {
        var environment = environment

        environment.readNotificationsEnabled = false
        adapter(&environment)
        environment.readNotificationsEnabled = true

        return environment
    }
}

/// Content storage that defers creation of its child until measurement or layout time.
private struct LazyStorage: ContentStorage {

    let childCount = 1

    var builder: (ElementContent.LayoutPhase, SizeConstraint, Environment) -> Element

    func measure(
        in constraint: SizeConstraint,
        with environment: Environment,
        states: ElementState
    ) -> CGSize {
        states.measure(in: constraint, with: environment) { environment in

            let child = buildChild(for: .measurement, in: constraint, environment: environment)
            let identifier = ElementIdentifier.identifier(for: child, key: nil, count: 1)
            let childState = states.childState(for: child, in: environment, with: identifier)

            return childState.elementContent.measure(
                in: constraint,
                with: environment,
                states: childState
            )
        }
    }

    func performLayout(
        in size: CGSize,
        with environment: Environment,
        states: ElementState
    ) -> [LayoutResultNode] {

        let constraint = SizeConstraint(size)
        let child = buildChild(for: .layout, in: constraint, environment: environment)

        let childAttributes = LayoutAttributes(size: size)

        let identifier = ElementIdentifier.identifier(for: child, key: nil, count: 1)

        let childState = states.childState(for: child, in: environment, with: identifier)

        let node = LayoutResultNode(
            element: child,
            identifier: identifier,
            layoutAttributes: childAttributes,
            environment: environment,
            state: childState,
            children: childState.elementContent.performLayout(
                in: size,
                with: environment,
                states: childState
            )
        )

        return [node]
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
        in size: CGSize,
        with environment: Environment,
        states: ElementState
    ) -> [LayoutResultNode] {
        []
    }

    func measure(in constraint: SizeConstraint, with environment: Environment, states: ElementState) -> CGSize {

        states.measure(in: constraint, with: environment) { environment in
            measurer(constraint, environment)
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

    // MARK: Layout

    func measure(in constraint: SizeConstraint, items: LayoutItems<Void>) -> CGSize {
        precondition(items.count == 1)

        return wrapped.measure(
            in: constraint,
            child: items.all[0].content
        )
    }

    func layout(size: CGSize, items: LayoutItems<Void>) -> [LayoutAttributes] {
        precondition(items.count == 1)

        return [
            wrapped.layout(
                size: size,
                child: items.all[0].content
            ),
        ]
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
}


// Used for empty elements with an intrinsic size
fileprivate struct MeasurableLayout: Layout {

    let measurable: Measurable

    func measure(in constraint: SizeConstraint, items: LayoutItems<Void>) -> CGSize {
        precondition(items.all.isEmpty)
        return measurable.measure(in: constraint)
    }

    func layout(size: CGSize, items: LayoutItems<Void>) -> [LayoutAttributes] {
        precondition(items.all.isEmpty)
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

